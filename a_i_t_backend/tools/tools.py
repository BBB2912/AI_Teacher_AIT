import app
import os
from serpapi import GoogleSearch
import app
from exa_py import Exa
import requests
import logging
from bs4 import BeautifulSoup
from dotenv import load_dotenv
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

class AITTools:
    """
    AITTools class provides methods to interact with various tools.
    """

    def __init__(self):
        self.exa_tool = self.setup_exa_tool()
        self.serp_api_key = os.getenv("SERPAPI_KEY")

    def setup_exa_tool(self):
        return Exa(os.getenv("EXA_API_KEY"))

    async def get_google_images(self, query, count=5):
        """Fetch top image URLs."""
        try:
            params = {
                "q": query,
                "engine": "google_images",
                "api_key": self.serp_api_key
            }
            search = GoogleSearch(params)
            results = search.get_dict()
            images = [img["original"]
                      for img in results.get("images_results", [])[:count]]
            logger.info("✅ Related Images fetched successfully.....!")
            return images
        except Exception as e:
            logger.info(f"❌ Related Images fetched Failes\n Reason:{str(e)}")
            

    async def get_google_videos(self, query, count=5):
        """Fetch top video URLs."""
        try:
            params = {
                "q": query,
                "engine": "google_videos",
                "api_key": self.serp_api_key
            }
            search = GoogleSearch(params)
            results = search.get_dict()
            videos = [vid["link"]
                      for vid in results.get("video_results", [])[:count]]

            logger.info("✅ Related Videos fetched successfully.....!")
            return videos
        except Exception as e:
            logger.info(f"❌ Related Videos fetched Failes\n Reason:{str(e)}")
    
    async def run_exa_search(self,user_instruction):
        try:
            result = self.exa_tool.search(
                user_instruction,
                type="auto",
                use_autoprompt=True
            )
            logger.info("✅ Exa search completed.....!")
            return result
        except Exception as e:
            logger.info(f"❌ Exa search Failes\n Reason:{str(e)}")

    # === Step 2: Extract URLs from search results ===
    def get_urls_from_results(self,result):
        urls = []
        for r in result.results:   # exa returns results as list
            if hasattr(r, "url") and r.url:
                urls.append(r.url)
        return urls

    # === Step 3: Fetch & clean text ===
    async def extract_text(self,url):
        try:
            response = requests.get(url, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
            response.raise_for_status()
            soup = BeautifulSoup(response.text, "html.parser")

            # remove useless tags
            for tag in soup(["script", "style", "noscript"]):
                tag.decompose()

            text = soup.get_text(separator="\n")
            # clean extra spaces/newlines
            text = "\n".join(line.strip() for line in text.splitlines() if line.strip())
            return text
        except Exception as e:
            logger.info(f"❌ web scrapping Fail for url:->{url}\n Reason:{str(e)}")
            return ''

    # === Step 4: Combine everything ===
    async def get_combined_content(self,user_instruction):
        try:
            search_results = await self.run_exa_search(user_instruction)
            urls =  self.get_urls_from_results(search_results)
            texts = []
            for url in urls[:5]:
                response = await self.extract_text(url)
                if response!='':
                    texts.append(response)
            
            combined = "\n".join(texts)
            logger.info("✅ Context extraction completed.....!")
            return {
                "status": "success",
                "response": combined
            }
            
        except Exception as e:
            logger.info(f"❌ Context extraction Failes\n Reason:{str(e)}")
            return {
                "status": "error",
                "error": str(e)
            }

    async def get_tool_response(self, userQuery):
        """
        Combines results from SerpAPI (images/videos) and Exa (content).
        Returns a formatted text block with [Headings] for Gemini.
        """
        try:
            images = await self.get_google_images(query=userQuery)
            videos = await self.get_google_videos(query=userQuery)
            content_result = await self.get_combined_content(user_instruction=userQuery)
            if content_result["status"] == "success":
                content_result = content_result["response"]
            else:
                content_result = "Content could not be fetched."
            
            # ---- Format the final text with [Headings] ----
            final_context = f"""
                [Related Content]
                {content_result}
                
                [Related Images]
                {chr(10).join(images) if images else "No images found."}
                
                [Related Videos]
                {chr(10).join(videos) if videos else "No videos found."}
                """
            logger.info("✅ Tool excution completed.....!")
            

            return {
                "status": "success",
                "response": final_context
            }

        except Exception as e:
            logger.info(f"❌ Tool excution Failes\n Reason:{str(e)}")
            return {
                "status": "error",
                "error": str(e)
            }
