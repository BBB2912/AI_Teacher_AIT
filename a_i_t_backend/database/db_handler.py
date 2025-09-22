import json
import os
import sqlite3
import aiosqlite
from dotenv import load_dotenv
import app
from models import StudentDataModel
import re
import logging
from models.user_request import TeacherResponseReqModel

# Load .env
dotenv_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(dotenv_path=dotenv_path)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

def sanitize_table_name(name: str):
    """Keep only letters, numbers, and underscores"""
    return re.sub(r'\W+', '_', name)


class DBHandler:
    def __init__(self):
        self.db_path = os.getenv("DB_PATH")
        self.user_db_folder = os.getenv("USER_DBS_FOLDER")
        os.makedirs(self.user_db_folder, exist_ok=True)
        print("Main DB Path:", self.db_path)
        print("User DB Folder:", self.user_db_folder)

        # Main DB connection (synchronous for setup)
        with sqlite3.connect(self.db_path) as db:
            cursor = db.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    name TEXT,
                    grade TEXT,
                    syllabus TEXT
                )
            """)
            db.commit()

        self.subjects = ["telugu", "hindi", "maths",
                         "history", "physics", "biology"]

    async def storeUserDetails(self, studentData: StudentDataModel):
        try:
            # Store user in main DB
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    "INSERT INTO users (id, name, grade, syllabus,profileImagePath) VALUES (?, ?, ?, ?,?)",
                    (studentData.userId, studentData.name,
                     studentData.grade, studentData.syllabus,studentData.profileImagePath),
                )
                await db.commit()

            # Create per-user DB
            user_db_path = os.path.join(
                self.user_db_folder, f"{sanitize_table_name(studentData.userId)}.db"
            )

            if not os.path.exists(user_db_path):
                db = await aiosqlite.connect(user_db_path)
                await db.close()
            logger.info("✅ user details storing completed.....!")

            
            return {"status": "success", "response": f"{studentData.name} details stored successfully"}
        except Exception as e:
            logger.info(f"❌ user details storing Failes\n Reason:{str(e)}")
            return {"status": "error", "response": str(e)}
        


    async def getUserDetails(self, uid: str):
        try:
            # Fetch user from main DB
            async with aiosqlite.connect(self.db_path) as db:
                cursor = await db.execute(
                    "SELECT * FROM users WHERE id = ?", (uid,)
                )
                row = await cursor.fetchone()
                await cursor.close()

            if not row:
                return {"status": "error", "response": f"User with id {uid} not found"}


            logger.info(f"✅ User details fetched for uid={uid}")

            # Assuming your users table has these columns (adjust if needed)
            user_data = {
                "id": row[0],
                "name": row[1],
                "grade": row[2],
                "syllabus": row[3],
                "profileImagePath": row[4]
            }

            return {"status": "success", "response": user_data}

        except Exception as e:
            logger.error(f"❌ Failed to get user details\nReason: {str(e)}")
            return {"status": "error", "response": str(e)}


    async def addchat(self,user_database_path:str,table_name:str,type:str,response:str):
        try:
            async with aiosqlite.connect(user_database_path) as user_db:
                # Create table if not exists
                await user_db.execute(f"""
                    CREATE TABLE IF NOT EXISTS {table_name} (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        type TEXT,
                        response TEXT,
                        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                """)

                # Insert chat
                await user_db.execute(f"""
                    INSERT INTO {table_name} (
                        type,
                        response
                    ) VALUES (?, ?)
                """, (
                    type,
                    response
                ))

                await user_db.commit()
                logger.info("✅ Request & Response storing completed.....!")
            return {"status": "success", "response": "Chat stored successfully"}

        except Exception as e:
            logger.info(f"❌ Request & Response storing Failes\n Reason:{str(e)}")
            return {"status": "error", "response": str(e)}
        
    async def adduserResponse(self,data: TeacherResponseReqModel,type,response):
        try:
            user_db_path = os.path.join(
                self.user_db_folder, f'{sanitize_table_name(data.userId)}.db'
            )

            table_name = sanitize_table_name(f"{data.userId}_{data.teacher}")

            await self.addchat(user_db_path,table_name,type,response)
            logger.info(f"✅ stored {type} resonse")
            return {"status": "success", "response": "Chat stored successfully"}

        except Exception as e:
            logger.info(f"❌ Request & Response storing Failes\n Reason:{str(e)}")
            return {"status": "error", "response": str(e)}

    

