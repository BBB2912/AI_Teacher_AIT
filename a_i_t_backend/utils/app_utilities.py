from prompts.prompts import Prompts
from dotenv import load_dotenv
import google.generativeai as genai
import os
import logging
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

class AITUtilities:
    def __init__(self):
        self.aiModel = self.load_model()


    def load_model(self):
        try:
            genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
            model_name = os.getenv("GEMINI_MODEL_NAME")
            model = genai.GenerativeModel(model_name)
            logger.info("✅ AI Teacher Model setup completed......!")
            return model
        except Exception as e:
            logger.info(f"❌ AI Teacher Model setup Failed\n Reason:{str(e)}")


    async def queryClassifier(self, user_query):
        classifierPrompt = Prompts.CLASSIFIER_PROMPT
        try:
            response = self.aiModel.generate_content(
                classifierPrompt.format(user_query=user_query)
            ).text.strip()
            logger.info("✅ query Classification Successfull.....!")
            return {
                "status":"success",
                "response":response
            }
        except Exception as e:
            logger.info(f"❌ query Classification Failes\n Reason:{str(e)}")
            return {
                "status":"error",
                "error":"There is Problem in Query Classisfier"
            }


    async def getTeacherResponse(self, prompt):
        try:
            response=self.aiModel.generate_content(prompt).text.strip()
            logger.info("✅ Teacher response generated.....!")
            return{
                "status":"success",
                "response":response
            }
        except Exception as e:
            logger.info(f"❌ Teacher response Failes\n Reason:{str(e)}")
            return {
                "status":"error",
                "error":"There is Problem in AI Teacher Response Classisfier"
            }

    def loadTeacherPrompt(self,teacher:str):
        return Prompts.TEACHER_PROMPTS[teacher.lower()]['template']