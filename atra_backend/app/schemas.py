from pydantic import BaseModel
from typing import List, Optional

# --- Job Order ---
class JobOrderBase(BaseModel):
    jo: str
    part: str
    required: int
    delivered: int

class JobOrderResponse(JobOrderBase):
    pass


# --- Project ---
class ProjectBase(BaseModel):
    id: str
    name: str
    version: str
    lastUpdate: str

class ProjectCreate(ProjectBase):
    jobOrders: List[JobOrderBase]

class ProjectResponse(ProjectBase):
    jobOrders: List[JobOrderResponse]


# --- User ---
class UserBase(BaseModel):
    id: str
    name: str
    role: str
    department: str
    avatar: Optional[str] = None
    password: Optional[str] = "0000"

class UserCreate(UserBase):
    pass

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(UserBase):
    pass


# --- Transfer ---
class TransferBase(BaseModel):
    id: str
    date: str
    project: str
    version: str
    jo: str
    part: str
    qty: int
    fromDept: str
    toDept: str
    status: str
    notes: str
    imageUrl: Optional[str] = None
    senderName: str
    receiverName: str

class TransferCreate(TransferBase):
    pass

class TransferResponse(TransferBase):
    pass


# --- Notification ---
class NotificationBase(BaseModel):
    id: str
    sender: str
    senderDept: str
    time: str
    project: str
    version: str
    part: str
    jo: str
    qty: int
    status: str
    type: str
    transferId: str
    toDept: str

class NotificationCreate(NotificationBase):
    pass

class NotificationResponse(NotificationBase):
    pass
