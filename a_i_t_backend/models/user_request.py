from pydantic import BaseModel


class TeacherResponseReqModel(BaseModel):
    studentDetails: dict
    userId:str
    userQuery: str
    teacher: str
