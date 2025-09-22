import asyncio
from fastapi import FastAPI, WebSocket, Query
import logging
import os
import re
import sqlite3
import aiosqlite
from fastapi import FastAPI, Query, WebSocket
from fastapi.responses import JSONResponse
from database import DBHandler
from models import StudentDataModel
from models import TeacherResponseReqModel
from fastapi.middleware.cors import CORSMiddleware
from utils import AITUtilities
from tools import AITTools
from dotenv import load_dotenv
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or restrict to ["http://localhost:3000"] etc.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

appUtilitis = AITUtilities()
appTools = AITTools()
dbHandler = DBHandler()



def sanitize_table_name(name: str):
    """Keep only letters, numbers, and underscores"""
    return re.sub(r'\W+', '_', name)


@app.post("/teacherResponse/")
async def getTeacherResponse(data: TeacherResponseReqModel):
    """based on user query and teacher type the ai teacher can process 
    the student request and return the response"""

    try:
        #store user query
        response=await dbHandler.adduserResponse(data,'user',data.userQuery)
        student = data.studentDetails
        contextString = (
            f"Student Name: {student['name']}, "
            f"Grade: {student['grade']}, "
            f"Syllabus: {student['syllabus']}, "
            f"Teacher: {data.teacher}, "
        )
        teacherPrompt = appUtilitis.loadTeacherPrompt(data.teacher)
        teacherResponse = None
        query_mode = await appUtilitis.queryClassifier(data.userQuery)
        if (query_mode['status'] == "success"):
            if (query_mode['response'].lower() == 'basic'):
                prompt = teacherPrompt.format(
                    student_details=contextString,
                    user_query=data.userQuery
                )
                teacherResponse = await appUtilitis.getTeacherResponse(prompt)
            elif (query_mode['response'].lower() == 'advanced'):
                toolResponse = await appTools.get_tool_response(data.userQuery)
                if (toolResponse['status'] == "success"):
                    teacherPrompt = teacherPrompt+'\n\n' + '{toolResponse}'

                    finalPrompt = teacherPrompt.format(
                        student_details=contextString,
                        user_query=data.userQuery,
                        toolResponse=toolResponse
                    )
                    teacherResponse = await appUtilitis.getTeacherResponse(finalPrompt)

                else:
                    teacherResponse = "teacher was empty"

        response = await dbHandler.adduserResponse(data,'teacher',teacherResponse['response'])
        if response['status'] == 'success':
            logger.info("✅ teacherResponse  completed.....!")
            return {"status": "success", "answer": teacherResponse['response']}
        else:
            logger.info(f"❌ teacherResponse Failes\n Reason:{str(e)}")
            return {"status": "error", "answer": response['response']}
    except Exception as e:
        logger.info(f"❌ teacherResponse Failes\n Reason:{str(e)}")
        return {"status": "error", "response": str(e)}


@app.post("/storeUserDetails/")
async def storeUserDetails(studentData: StudentDataModel):
    try:
        response = await dbHandler.storeUserDetails(studentData)
        if response['status'] == 'success':
            logger.info("✅ storeUserDetails  completed.....!")
            return {
                "status": "success",
                "message": response['response']
            }
        else:
            logger.info(
                f"❌ storeUserDetails Failes\n Reason:{response['response']}")
            return {
                "status": "error",
                "message": response['response']
            }
    except Exception as e:
        logger.info(f"❌ storeUserDetails Failes\n Reason:{str(e)}")
        return {
            "status": "error",
            "message": str(e)
        }
@app.get("/getUserDetails/{uid}")
async def getUserDetails(uid: str):
    try:
        userData = await dbHandler.getUserDetails(uid)

        if userData["status"] == "error":
            return JSONResponse(
                status_code=404,
                content=userData
            )

        return JSONResponse(
            status_code=200,
            content=userData
        )

    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"status": "error", "response": str(e)}
        )
    
    

def sanitize_table_name(name: str) -> str:
    return re.sub(r'\W+', '_', name)


@app.websocket("/ws/messages")
async def websocket_endpoint(
    websocket: WebSocket,
    uid: str = Query(...),
    teacher: str = Query(...)
):
    await websocket.accept()

    # load .env
    dotenvpath = os.path.join("database", ".env")
    load_dotenv(dotenv_path=dotenvpath)
    user_db_folder = os.getenv("USER_DBS_FOLDER")

    # ensure folder exists
    os.makedirs(user_db_folder, exist_ok=True)

    # one DB file per user
    user_db_path = os.path.join(
        user_db_folder, f"{sanitize_table_name(uid)}.db")

    # one table per teacher
    table_name = sanitize_table_name(f"{uid}_{teacher}")

    async with aiosqlite.connect(user_db_path) as user_db:
        # create table if not exists
        await user_db.execute(f"""
                    CREATE TABLE IF NOT EXISTS {table_name} (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        type TEXT,
                        response TEXT,
                        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                """)
        await user_db.commit()

        # live loop
        while True:
            cursor = await user_db.execute(f"SELECT * FROM {table_name} ORDER BY id ASC")
            rows = await cursor.fetchall()
            cols = [desc[0] for desc in cursor.description]
            await cursor.close()

            # convert rows → list[dict]
            messages = [dict(zip(cols, row)) for row in rows]

            await websocket.send_json(messages)
            await asyncio.sleep(2)  # poll every 2 sec (can optimize later)
