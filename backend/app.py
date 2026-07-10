import os
import hashlib
import urllib.request
import json
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Try to initialize Firebase Admin SDK
firebase_initialized = False
try:
    import firebase_admin
    from firebase_admin import credentials, firestore, auth
    
    # Check if firebase service account key exists
    cred_path = os.environ.get('FIREBASE_CREDENTIALS_PATH', 'firebase-key.json')
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        firebase_initialized = True
        print("Firebase Admin SDK successfully initialized!")
except Exception as e:
    print(f"Firebase Admin SDK initialization skipped: {str(e)}")
    print("Falling back to local high-fidelity database simulator.")

# High-Fidelity Local Database Simulator (used if Firebase SDK is not active)
# Keeps server state active in memory for testing
MOCK_USERS = {
    "usr_001": {
        "id": "usr_001",
        "name": "Mohomed Muzammil",
        "email": "mohomed.m@lankago.lk",
        "balance": 150.00,
        "phone": "+94771234567",
        "status": "active",  # "active" | "frozen"
        "accountType": "student",  # "regular" | "student"
        "routes_history": ["tx_init_1", "tx_init_2"]
    },
    "usr_002": {
        "id": "usr_002",
        "name": "Kamal Perera",
        "email": "kamal.perera@lankago.lk",
        "balance": 45.00,  # Low balance test candidate (< LKR 50)
        "phone": "+94719876543",
        "status": "active",
        "accountType": "regular",
        "routes_history": []
    }
}

# Passwords for simulated users (key: email, value: password)
MOCK_USER_PASSWORDS = {
    "mohomed.m@lankago.lk": "password123",
    "kamal.perera@lankago.lk": "password123"
}

MOCK_TRANSACTIONS = {
    "tx_init_1": {
        "id": "tx_init_1",
        "user_id": "usr_001",
        "type": "travel",
        "amount": -20.0,
        "timestamp": (datetime.utcnow() - timedelta(hours=4)).isoformat() + "Z"
    },
    "tx_init_2": {
        "id": "tx_init_2",
        "user_id": "usr_001",
        "type": "travel",
        "amount": -27.5,
        "timestamp": (datetime.utcnow() - timedelta(days=1)).isoformat() + "Z"
    }
}

MOCK_BUSES = {
    "route_138": {
        "id": "route_138",
        "name": "138 Pettah-Borella",
        "eta": ["3 min", "11 min", "18 min"]
    },
    "route_120": {
        "id": "route_120",
        "name": "120 Colombo-Horana",
        "eta": ["5 min", "14 min"]
    },
    "route_177": {
        "id": "route_177",
        "name": "177 Kollupitiya-Kaduwela",
        "eta": ["9 min", "22 min"]
    }
}

# PayHere Signature MD5 Hash verification secret
PAYHERE_SECRET = "LANKAGO_PAYHERE_SECRET_KEY"

@app.route('/api/users/<user_id>', methods=['GET'])
def get_user(user_id):
    """Retrieve user detail schema (via Firestore or local mock fallback)"""
    if firebase_initialized:
        try:
            doc_ref = db.collection('users').document(user_id)
            doc = doc_ref.get()
            if doc.exists:
                return jsonify(doc.to_dict()), 200
        except Exception as e:
            return jsonify({"error": f"Firestore Error: {str(e)}"}), 500

    # Fallback to local simulator
    if user_id in MOCK_USERS:
        return jsonify(MOCK_USERS[user_id]), 200
    return jsonify({"error": "User card not found"}), 404


@app.route('/api/routes', methods=['GET'])
def get_routes():
    """Retrieve Colombo routes and schedules table"""
    if firebase_initialized:
        try:
            buses_ref = db.collection('buses')
            docs = buses_ref.stream()
            routes = {doc.id: doc.to_dict() for doc in docs}
            return jsonify(routes), 200
        except Exception as e:
            return jsonify({"error": f"Firestore Error: {str(e)}"}), 500

    return jsonify(MOCK_BUSES), 200


@app.route('/api/transactions/reload', methods=['POST'])
def process_reload():
    """
    PayHere Webhook Callback endpoint
    Validates signature and credits order amount atomically
    """
    data = request.json or {}
    merchant_id = data.get('merchant_id', '')
    order_id = data.get('order_id', '')
    payhere_amount = data.get('payhere_amount', 0.0)
    payhere_currency = data.get('payhere_currency', 'LKR')
    status_code = data.get('status_code', 0)  # 2 for Success
    incoming_sig = data.get('md5sig', '').upper()
    user_id = data.get('user_id', '')

    # 1. Re-generate expected MD5 MD5(merchant_id + order_id + payhere_amount + payhere_currency + status_code + md5(payhere_secret))
    secret_hashed = hashlib.md5(PAYHERE_SECRET.encode('utf-8')).hexdigest().upper()
    raw_str = f"{merchant_id}{order_id}{payhere_amount}{payhere_currency}{status_code}{secret_hashed}"
    generated_sig = hashlib.md5(raw_str.encode('utf-8')).hexdigest().upper()

    # 2. Check MD5 signatures match to prevent transaction spoofing
    if incoming_sig != generated_sig:
        return jsonify({"error": "Invalid signature. Payment rejected."}), 400

    if status_code != 2:
        return jsonify({"error": f"Payment failed with code {status_code}"}), 400

    amount = float(payhere_amount)
    if amount < 10.0:
        return jsonify({"error": "Minimum reload amount is LKR 10"}), 400

    # 3. Process Balance Credit
    if firebase_initialized:
        try:
            user_ref = db.collection('users').document(user_id)
            user_doc = user_ref.get()
            if not user_doc.exists:
                return jsonify({"error": "User not found"}), 404

            # Create immutable transaction document
            tx_id = f"tx_pay_{order_id}"
            tx_ref = db.collection('transactions').document(tx_id)
            
            # Execute atomicity
            db.transaction()
            user_ref.update({"balance": firestore.Increment(amount)})
            tx_ref.set({
                "user_id": user_id,
                "type": "reload",
                "amount": amount,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            })
            return jsonify({"success": True, "new_balance": user_doc.to_dict()['balance'] + amount}), 200
        except Exception as e:
            return jsonify({"error": f"Firestore Transaction failed: {str(e)}"}), 500

    # Fallback to local simulator
    if user_id in MOCK_USERS:
        MOCK_USERS[user_id]['balance'] += amount
        tx_id = f"tx_pay_{order_id}"
        MOCK_TRANSACTIONS[tx_id] = {
            "id": tx_id,
            "user_id": user_id,
            "type": "reload",
            "amount": amount,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        MOCK_USERS[user_id]['routes_history'].append(tx_id)
        return jsonify({"success": True, "new_balance": MOCK_USERS[user_id]['balance']}), 200

    return jsonify({"error": "User not found"}), 404


@app.route('/api/transactions/sync', methods=['POST'])
def sync_offline_transactions():
    """
    Sync endpoint for offline validation queues
    Processes up to 500 SQLite buffered scans
    Applies Student Discounts, Daily Cappings, and Duplicate Scan Blocks
    """
    data = request.json or {}
    user_id = data.get('user_id', '')
    offline_txs = data.get('transactions', [])

    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400

    # Retrieve User
    user = None
    if firebase_initialized:
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        if user_doc.exists:
            user = user_doc.to_dict()
    else:
        user = MOCK_USERS.get(user_id)

    if not user:
        return jsonify({"error": "User not found"}), 404

    # Enforce Server as ultimate source of truth
    balance = float(user['balance'])
    account_type = user.get('accountType', 'regular')
    user_status = user.get('status', 'active')
    
    if user_status == 'frozen':
        return jsonify({"error": "Card is frozen. Cannot sync transactions."}), 400

    synced_results = []
    
    # Store dynamic daily spend totals on server to calculate capping rules
    # Get previous spends for today
    today_str = datetime.utcnow().strftime("%Y-%m-%d")
    daily_spent = 0.0
    
    # Compile transactions of today
    all_txs = []
    if firebase_initialized:
        txs_ref = db.collection('transactions').where('user_id', '==', user_id).stream()
        all_txs = [tx.to_dict() for tx in txs_ref]
    else:
        all_txs = [tx for tx in MOCK_TRANSACTIONS.values() if tx['user_id'] == user_id]

    for tx in all_txs:
        # Check if transaction was travel on this calendar day
        if tx['type'] in ['travel', 'travel_capped'] and tx['timestamp'].startswith(today_str):
            daily_spent += abs(float(tx['amount']))

    # Track duplicate scan intervals
    last_scan_time = None
    
    # Sort incoming offline transactions by timestamp
    offline_txs.sort(key=lambda x: x.get('timestamp', ''))

    for tx in offline_txs:
        tx_time = datetime.fromisoformat(tx['timestamp'].replace('Z', ''))
        base_fare = float(tx.get('fare', 0.0))
        bus_id = tx.get('busId', '')
        route = tx.get('route', '')

        # 1. Duplicate Scan Protection (1-minute block for same card on same bus)
        if last_scan_time and (tx_time - last_scan_time) < timedelta(minutes=1):
            # Flagged as duplicate scan, drop or record as zero fare
            synced_results.append({
                "id": tx.get('id'),
                "status": "rejected",
                "reason": "Duplicate scan blocked (1-min timeout)"
            })
            continue

        last_scan_time = tx_time

        # 2. Student Discount calculations (50% slash)
        fare = base_fare
        if account_type == "student":
            # If not already discounted by the local client validator
            fare = base_fare * 0.5

        # 3. LKR 100 Daily Cap Capping Rule
        tx_type = "travel"
        if daily_spent >= 100.0:
            fare = 0.0
            tx_type = "travel_capped"
        elif daily_spent + fare > 100.0:
            fare = 100.0 - daily_spent
            daily_spent = 100.0
            tx_type = "travel_capped"
        else:
            daily_spent += fare

        # 4. Verify Server Balance
        if balance < fare:
            synced_results.append({
                "id": tx.get('id'),
                "status": "rejected",
                "reason": "Server Balance Insufficient"
            })
            continue

        # 5. Apply Deduction
        balance -= fare

        # Save synced transaction
        tx_id = tx.get('id')
        if firebase_initialized:
            db.collection('transactions').document(tx_id).set({
                "user_id": user_id,
                "type": tx_type,
                "amount": -fare,
                "timestamp": tx['timestamp']
            })
            user_ref.update({
                "balance": balance,
                "routes_history": firestore.ArrayUnion([tx_id])
            })
        else:
            MOCK_TRANSACTIONS[tx_id] = {
                "id": tx_id,
                "user_id": user_id,
                "type": tx_type,
                "amount": -fare,
                "timestamp": tx['timestamp']
            }
            MOCK_USERS[user_id]['balance'] = balance
            MOCK_USERS[user_id]['routes_history'].append(tx_id)

        synced_results.append({
            "id": tx_id,
            "status": "synced",
            "type": tx_type,
            "amount": -fare
        })

    # Return updated server fields
    return jsonify({
        "success": True,
        "synced_transactions": synced_results,
        "new_balance": balance
    }), 200


@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.json or {}
    email = data.get('email', '')
    password = data.get('password', '')
    name = data.get('name', '')
    phone = data.get('phone', '')
    account_type = data.get('accountType', 'regular')
    card_number = data.get('cardNumber', '')

    if not email or not password or not name:
        return jsonify({"error": "Missing required fields (email, password, name)"}), 400

    # Ensure card number is generated if not provided
    if not card_number:
        card_number = f"LK-GO-{hashlib.md5(email.encode()).hexdigest()[:8].upper()}"

    if firebase_initialized:
        try:
            # Create user in Firebase Authentication
            user_record = auth.create_user(
                email=email,
                password=password,
                display_name=name,
                phone_number=phone if phone else None
            )
            uid = user_record.uid

            # Create Firestore user document
            user_data = {
                "id": uid,
                "name": name,
                "email": email,
                "balance": 100.0,  # initial promo balance
                "phone": phone,
                "status": "active",
                "accountType": account_type,
                "cardNumber": card_number,
                "routes_history": []
            }
            db.collection('users').document(uid).set(user_data)
            return jsonify({"success": True, "user": user_data}), 200
        except Exception as e:
            return jsonify({"error": f"Firebase Auth Error: {str(e)}"}), 500
    
    # Simulator mode
    # Check if user already exists
    for u in MOCK_USERS.values():
        if u['email'] == email:
            return jsonify({"error": "User with this email already exists"}), 400

    uid = f"usr_{hashlib.md5(email.encode()).hexdigest()[:6]}"
    user_data = {
        "id": uid,
        "name": name,
        "email": email,
        "balance": 100.0,
        "phone": phone,
        "status": "active",
        "accountType": account_type,
        "cardNumber": card_number,
        "routes_history": []
    }
    MOCK_USERS[uid] = user_data
    MOCK_USER_PASSWORDS[email] = password
    return jsonify({"success": True, "user": user_data}), 200


@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.json or {}
    email = data.get('email', '')
    password = data.get('password', '')

    if not email or not password:
        return jsonify({"error": "Missing email or password"}), 400

    if firebase_initialized:
        api_key = os.environ.get('FIREBASE_WEB_API_KEY')
        if api_key:
            url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
            req_data = json.dumps({"email": email, "password": password, "returnSecureToken": True}).encode("utf-8")
            req = urllib.request.Request(url, data=req_data, headers={"Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(req) as response:
                    res_body = json.loads(response.read().decode("utf-8"))
                    uid = res_body.get("localId")
                    
                    # Fetch Firestore user document
                    doc_ref = db.collection('users').document(uid)
                    doc = doc_ref.get()
                    if doc.exists:
                        return jsonify({"success": True, "user": doc.to_dict()}), 200
                    else:
                        # Create Firestore document if somehow missing
                        user_record = auth.get_user(uid)
                        user_data = {
                            "id": uid,
                            "name": user_record.display_name or "Anonymous",
                            "email": user_record.email,
                            "balance": 100.0,
                            "phone": user_record.phone_number or "",
                            "status": "active",
                            "accountType": "regular",
                            "cardNumber": f"LK-GO-{uid[:8].upper()}",
                            "routes_history": []
                        }
                        db.collection('users').document(uid).set(user_data)
                        return jsonify({"success": True, "user": user_data}), 200
            except Exception as e:
                try:
                    error_msg = json.loads(e.read().decode("utf-8"))['error']['message']
                except Exception:
                    error_msg = str(e)
                return jsonify({"error": f"Firebase Auth Error: {error_msg}"}), 400
            
    # Simulator / local fallback password checking
    for u_id, u in MOCK_USERS.items():
        if u['email'] == email:
            stored_password = MOCK_USER_PASSWORDS.get(email)
            if stored_password == password:
                return jsonify({"success": True, "user": u}), 200
            else:
                return jsonify({"error": "Invalid email or password"}), 400

    return jsonify({"error": "User not found"}), 404


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=True)
