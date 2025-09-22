from pydantic import BaseModel


class StudentDataModel(BaseModel):
    name: str
    grade: str
    syllabus: str
    userId: str
    profileImagePath:str
