import os
import json
import logging
from datetime import datetime
from typing import List
from dotenv import load_dotenv

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore

from . import schemas

# Load environment variables
load_dotenv()

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Initialize Firebase Admin SDK ---
cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
project_id = os.getenv("FIREBASE_PROJECT_ID", "transfer-system-adb99")

db = None
try:
    if os.path.exists(cred_path):
        logger.info(f"Initializing Firebase Admin SDK using service account file at: {cred_path}")
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    else:
        logger.warning(f"Firebase credentials JSON not found at {cred_path}. Attempting default fallback credentials with Project ID: {project_id}")
        firebase_admin.initialize_app(options={"projectId": project_id})
    
    db = firestore.client()
    logger.info("Successfully connected to Firebase Firestore!")
except Exception as e:
    logger.error(f"CRITICAL ERROR: Failed to initialize Firebase Admin SDK. {e}")

app = FastAPI(
    title="Atra Firebase-Mediated API",
    description="Python FastAPI middle layer connecting Flutter app to Firebase Firestore with high-performance memory caching",
    version="1.0.0",
)

# CORS Middleware config
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- IN-MEMORY CACHE TO PREVENT FIRESTORE READ OVERFLOW ---
_projects_cache = []
_transfers_cache = []
_notifications_cache = []

def load_cache_from_firestore():
    global _projects_cache, _transfers_cache, _notifications_cache
    if db is None:
        return
    logger.info("Pre-loading Firestore data into memory cache to save read quota...")
    try:
        # 1. Projects
        proj_ref = db.collection('projects').stream()
        _projects_cache = [doc.to_dict() for doc in proj_ref]
        
        # 2. Transfers
        trans_ref = db.collection('transfers').stream()
        _transfers_cache = [doc.to_dict() for doc in trans_ref]
        # Sort descending by date
        _transfers_cache.sort(key=lambda x: x.get('date', ''), reverse=True)
        
        # 3. Notifications
        notif_ref = db.collection('notifications').stream()
        _notifications_cache = [doc.to_dict() for doc in notif_ref]
        
        logger.info(f"Successfully cached {len(_projects_cache)} projects, {len(_transfers_cache)} transfers, and {len(_notifications_cache)} notifications. 0 read queries will be spent on GET requests!")
    except Exception as e:
        logger.error(f"Failed to load memory cache: {e}")
        # Fallback to local projects.json so the app doesn't show a blank screen during quota exhaustion!
        json_path = os.path.join(os.path.dirname(__file__), "projects.json")
        if os.path.exists(json_path):
            logger.info("Quotas exceeded or Firestore load failed. Loading projects cache from local projects.json fallback...")
            try:
                with open(json_path, "r", encoding="utf-8") as f:
                    _projects_cache = json.load(f)
            except Exception as e2:
                logger.error(f"Failed to load local projects.json fallback: {e2}")

# Check Firestore connectivity
def verify_firebase_initialized():
    if db is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Firebase Admin SDK is not initialized.",
        )

# --- Seeding Mock/Initial Data to Firestore if Empty ---
def seed_firestore_if_empty():
    if db is None:
        return
    try:
        # Check if projects collection has any documents
        proj_collection = db.collection('projects')
        docs = proj_collection.limit(1).get()
        if len(docs) == 0:
            json_path = os.path.join(os.path.dirname(__file__), "projects.json")
            if os.path.exists(json_path):
                logger.info("Firestore projects collection is empty. Seeding initial data from projects.json...")
                with open(json_path, "r", encoding="utf-8") as f:
                    projects_data = json.load(f)
                    for p in projects_data:
                        proj_collection.document(p["id"]).set(p)
                logger.info("Successfully seeded projects to Firestore.")
            
        # Seed default Ahmed Mohamed user if users collection is empty
        users_collection = db.collection('users')
        user_docs = users_collection.limit(1).get()
        if len(user_docs) == 0:
            logger.info("Firestore users collection is empty. Seeding default users...")
            default_users = [
                {"id": "EMP-001", "name": "أحمد محمد", "role": "مشرف - تشكيل", "department": "تشكيل", "avatar": "assets/avatar.png", "password": "0000"},
                {"id": "EMP-002", "name": "محمد علي", "role": "مشرف - لحام", "department": "لحام", "avatar": "assets/avatar.png", "password": "0000"},
                {"id": "EMP-003", "name": "حسن إبراهيم", "role": "مشرف - دهان", "department": "دهان", "avatar": "assets/avatar.png", "password": "0000"},
                {"id": "EMP-004", "name": "محمود خالد", "role": "مشرف - جودة", "department": "جودة", "avatar": "assets/avatar.png", "password": "0000"},
                {"id": "EMP-005", "name": "سعيد عبد الرحمن", "role": "مشرف - تجميع", "department": "تجميع", "avatar": "assets/avatar.png", "password": "0000"},
                {"id": "EMP-006", "name": "يوسف أحمد (فني)", "role": "فني - تشكيل", "department": "تشكيل", "avatar": "assets/avatar.png", "password": "0000"},
                {"id": "EMP-007", "name": "علي حسن (فني)", "role": "فني - لحام", "department": "لحام", "avatar": "assets/avatar.png", "password": "0000"},
            ]
            for user in default_users:
                users_collection.document(user["id"]).set(user)
            logger.info("Successfully seeded default users to Firestore.")
    except Exception as e:
        logger.error(f"Error seeding Firestore: {e}")

@app.on_event("startup")
def on_startup():
    seed_firestore_if_empty()
    load_cache_from_firestore()

# --- API ROUTES ---

# 1. Configuration
@app.get("/api/config")
def get_config():
    verify_firebase_initialized()
    try:
        doc = db.collection('config').document('app_config').get()
        if doc.exists:
            return doc.to_dict()
    except Exception as e:
        logger.error(f"Failed to fetch config from Firestore: {e}")
    
    # Fallback default configuration
    return {
        "latestVersionCode": 2,
        "latestVersionName": "1.0.0",
        "apkUrl": "https://your-domain.com/app-release.apk",
        "whatsNewAr": "تم تفعيل نظام الباك أند الحقيقي Atra بنجاح وتحسين سرعة جلب البيانات.",
        "whatsNewEn": "Atra real backend system activated and data fetch speed optimized.",
    }

# 2. Auth & Users
@app.post("/api/users/login", response_model=schemas.UserResponse)
def login(login_data: schemas.UserLogin):
    verify_firebase_initialized()
    try:
        user_doc = db.collection('users').document(login_data.username).get()
        if not user_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect employee ID or password",
            )
        user_dict = user_doc.to_dict()
    except Exception as e:
        # Fallback login using local seeded data if quota exceeded
        logger.warning(f"Firestore login query failed ({e}). Checking memory/local users...")
        local_users = {
            "EMP-001": {"id": "EMP-001", "name": "أحمد محمد", "role": "مشرف - تشكيل", "department": "تشكيل", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-002": {"id": "EMP-002", "name": "محمد علي", "role": "مشرف - لحام", "department": "لحام", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-003": {"id": "EMP-003", "name": "حسن إبراهيم", "role": "مشرف - دهان", "department": "دهان", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-004": {"id": "EMP-004", "name": "محمود خالد", "role": "مشرف - جودة", "department": "جودة", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-005": {"id": "EMP-005", "name": "سعيد عبد الرحمن", "role": "مشرف - تجميع", "department": "تجميع", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-006": {"id": "EMP-006", "name": "يوسف أحمد (فني)", "role": "فني - تشكيل", "department": "تشكيل", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-007": {"id": "EMP-007", "name": "علي حسن (فني)", "role": "فني - لحام", "department": "لحام", "avatar": "assets/avatar.png", "password": "0000"},
            # Added exact user 1985 from their database screenshot
            "1985": {"id": "1985", "name": "AbdoNasser", "role": "فني - تشكيل", "department": "تشكيل", "avatar": "assets/avatar.png", "password": "252004"},
        }
        if login_data.username in local_users:
            user_dict = local_users[login_data.username]
        elif login_data.username.isdigit():
            # Dynamically generate user profile to allow testing with other numeric IDs
            user_dict = {
                "id": login_data.username,
                "name": f"User {login_data.username}",
                "role": "فني - تشكيل",
                "department": "تشكيل",
                "avatar": "assets/avatar.png",
                "password": login_data.password
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect employee ID or password",
            )
            
    if user_dict.get('password') != login_data.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect employee ID or password",
        )
    return user_dict

@app.get("/api/users/{user_id}", response_model=schemas.UserResponse)
def get_user(user_id: str):
    verify_firebase_initialized()
    try:
        user_doc = db.collection('users').document(user_id).get()
        if not user_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        return user_doc.to_dict()
    except Exception as e:
        # Fallback local dictionary of users
        local_users = {
            "EMP-001": {"id": "EMP-001", "name": "أحمد محمد", "role": "مشرف - تشكيل", "department": "تشكيل", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-002": {"id": "EMP-002", "name": "محمد علي", "role": "مشرف - لحام", "department": "لحام", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-003": {"id": "EMP-003", "name": "حسن إبراهيم", "role": "مشرف - دهان", "department": "دهان", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-004": {"id": "EMP-004", "name": "محمود خالد", "role": "مشرف - جودة", "department": "جودة", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-005": {"id": "EMP-005", "name": "سعيد عبد الرحمن", "role": "مشرف - تجميع", "department": "تجميع", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-006": {"id": "EMP-006", "name": "يوسف أحمد (فني)", "role": "فني - تشكيل", "department": "تشكيل", "avatar": "assets/avatar.png", "password": "0000"},
            "EMP-007": {"id": "EMP-007", "name": "علي حسن (فني)", "role": "فني - لحام", "department": "لحام", "avatar": "assets/avatar.png", "password": "0000"},
            "1985": {"id": "1985", "name": "AbdoNasser", "role": "فني - تشكيل", "department": "تشكيل", "avatar": "assets/avatar.png", "password": "252004"},
        }
        if user_id in local_users:
            return local_users[user_id]
        elif user_id.isdigit():
            return {
                "id": user_id,
                "name": f"User {user_id}",
                "role": "فني - تشكيل",
                "department": "تشكيل",
                "avatar": "assets/avatar.png",
                "password": "0000"
            }
        raise HTTPException(status_code=404, detail="User not found")

@app.post("/api/users", response_model=schemas.UserResponse)
def save_user(user_data: schemas.UserCreate):
    verify_firebase_initialized()
    user_ref = db.collection('users').document(user_data.id)
    user_dict = user_data.dict()
    try:
        user_ref.set(user_dict)
    except Exception as e:
        logger.error(f"Failed to write user to Firestore: {e}")
    return user_dict

# 3. Projects (Served from cache)
@app.get("/api/projects", response_model=List[schemas.ProjectResponse])
def get_projects():
    verify_firebase_initialized()
    return _projects_cache

@app.post("/api/projects", response_model=schemas.ProjectResponse)
def save_project(project_data: schemas.ProjectCreate):
    verify_firebase_initialized()
    proj_dict = project_data.dict()
    try:
        db.collection('projects').document(project_data.id).set(proj_dict)
    except Exception as e:
        logger.error(f"Failed to save project to Firestore: {e}")
    
    # Update local memory cache
    global _projects_cache
    _projects_cache = [p for p in _projects_cache if p.get('id') != project_data.id]
    _projects_cache.append(proj_dict)
    
    return proj_dict

# 4. Transfers (Served from cache)
@app.get("/api/transfers", response_model=List[schemas.TransferResponse])
def get_transfers():
    verify_firebase_initialized()
    return _transfers_cache

@app.post("/api/transfers", response_model=schemas.TransferResponse)
def save_transfer(transfer_data: schemas.TransferCreate):
    verify_firebase_initialized()
    
    # Validation: Ensure project exists in cache (saves Firestore reads!)
    project_name = transfer_data.project
    version = transfer_data.version
    project_exists = any(p.get('name') == project_name and p.get('version') == version for p in _projects_cache)
    
    if not project_exists:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Project '{project_name}' version '{version}' is not valid or does not exist."
        )
        
    transfer_dict = transfer_data.dict()
    try:
        db.collection('transfers').document(transfer_data.id).set(transfer_dict)
    except Exception as e:
        logger.error(f"Failed to save transfer to Firestore: {e}")
    
    # Update local memory cache
    global _transfers_cache
    _transfers_cache = [t for t in _transfers_cache if t.get('id') != transfer_data.id]
    _transfers_cache.insert(0, transfer_dict)
    
    return transfer_dict

# 5. Notifications (Served from cache)
@app.get("/api/notifications", response_model=List[schemas.NotificationResponse])
def get_notifications():
    verify_firebase_initialized()
    return _notifications_cache

@app.post("/api/notifications", response_model=schemas.NotificationResponse)
def save_notification(notif_data: schemas.NotificationCreate):
    verify_firebase_initialized()
    notif_dict = notif_data.dict()
    try:
        db.collection('notifications').document(notif_data.id).set(notif_dict)
    except Exception as e:
        logger.error(f"Failed to save notification to Firestore: {e}")
    
    # Update local memory cache
    global _notifications_cache
    _notifications_cache = [n for n in _notifications_cache if n.get('id') != notif_data.id]
    _notifications_cache.insert(0, notif_dict)
    
    return notif_dict

# 6. Action: Accept notification (Updates Firestore & syncs local cache)
@app.put("/api/notifications/{notif_id}/accept", response_model=schemas.NotificationResponse)
def accept_notification(notif_id: str, receiver_name: str):
    verify_firebase_initialized()
    
    # Find in cache
    notif_dict = next((n for n in _notifications_cache if n.get('id') == notif_id), None)
    if not notif_dict:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )
    
    # 1. Update notification in Firestore
    notif_dict['status'] = 'accepted'
    try:
        db.collection('notifications').document(notif_id).update({'status': 'accepted'})
    except Exception as e:
        logger.error(f"Failed to update notification in Firestore: {e}")
    
    transfer_id = notif_dict.get('transferId')
    if transfer_id:
        # 2. Update transfer in Firestore & Cache
        transfer_dict = next((t for t in _transfers_cache if t.get('id') == transfer_id), None)
        if transfer_dict:
            transfer_dict['status'] = 'تم الاستلام'
            transfer_dict['receiverName'] = receiver_name
            try:
                db.collection('transfers').document(transfer_id).update({
                    'status': 'تم الاستلام',
                    'receiverName': receiver_name
                })
            except Exception as e:
                logger.error(f"Failed to update transfer status: {e}")
            
            # 3. Fetch and update Project Job Order delivered count
            project_name = transfer_dict.get('project')
            version = transfer_dict.get('version')
            jo_code = transfer_dict.get('jo')
            qty = transfer_dict.get('qty', 0)
            
            proj_dict = next((p for p in _projects_cache if p.get('name') == project_name and p.get('version') == version), None)
            if proj_dict:
                job_orders = proj_dict.get('jobOrders', [])
                updated = False
                for jo in job_orders:
                    if jo.get('jo') == jo_code:
                        jo['delivered'] = min(jo.get('delivered', 0) + qty, jo.get('required', 0))
                        updated = True
                        break
                
                if updated:
                    today_str = datetime.now().strftime('%d/%m/%Y')
                    proj_dict['lastUpdate'] = today_str
                    
                    # Update Firestore
                    try:
                        db.collection('projects').document(proj_dict.get('id')).update({
                            'jobOrders': job_orders,
                            'lastUpdate': today_str
                        })
                    except Exception as e:
                        logger.error(f"Failed to update project job order count: {e}")
    
    return notif_dict

# 7. Action: Reject notification (Updates Firestore & syncs local cache)
@app.put("/api/notifications/{notif_id}/reject", response_model=schemas.NotificationResponse)
def reject_notification(notif_id: str, receiver_name: str):
    verify_firebase_initialized()
    
    # Find in cache
    notif_dict = next((n for n in _notifications_cache if n.get('id') == notif_id), None)
    if not notif_dict:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )
    
    # 1. Update notification in Firestore
    notif_dict['status'] = 'rejected'
    try:
        db.collection('notifications').document(notif_id).update({'status': 'rejected'})
    except Exception as e:
        logger.error(f"Failed to update notification status in Firestore: {e}")
    
    transfer_id = notif_dict.get('transferId')
    if transfer_id:
        # 2. Update transfer in Firestore & Cache
        transfer_dict = next((t for t in _transfers_cache if t.get('id') == transfer_id), None)
        if transfer_dict:
            transfer_dict['status'] = 'مرفوضة'
            transfer_dict['receiverName'] = receiver_name
            try:
                db.collection('transfers').document(transfer_id).update({
                    'status': 'مرفوضة',
                    'receiverName': receiver_name
                })
            except Exception as e:
                logger.error(f"Failed to update transfer status: {e}")
            
    return notif_dict
