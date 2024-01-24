import requests
from bs4 import BeautifulSoup
from openai import OpenAI
import os

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

# Ensure you have your OpenAI API key set in your environment variables

def crawl_and_parse(base_url, routes):
    articles = []
    for route in routes:
        url = base_url + route
        try:
            response = requests.get(url)
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                guide_articles = soup.find_all(class_=lambda x: x and x.startswith('guide-article_content'))
                articles.extend([article.get_text() for article in guide_articles])
            else:
                print(f"Failed to fetch data from {url}")
        except requests.RequestException as e:
            print(f"An error occurred while fetching data from {url}: {e}")
    return articles

def generate_quiz(article_content):
    messages = [
        {"role": "system", "content": "You are a helpful assistant. Create a detailed 5 question quiz based on the given article content that tests player's ability to add value to the group and mitigate risk of group members dying."},
        {"role": "user", "content": article_content}
    ]
    response = client.chat.completions.create(
        model="gpt-4",
        messages=messages
    )
    return response.choices[0].message.content

def grade_answers(user_answers, article):
    messages = [
        {"role": "system", "content": "You are a helpful assistant. Grade the user's answers based on the provided article content."},
        {"role": "user", "content": f"Article Content:\n{article}\n\nUser Answers:\n{user_answers}"}
    ]
    response = client.chat.completions.create(
        model="gpt-4",
        messages=messages
    )
    return response.choices[0].message.content


def main():
    base_url = "https://www.hcguides.com/dungeons"
    routes = ["/wailing-caverns", "/the-deadmines", "/shadowfang-keep"]  # Example routes

    articles = crawl_and_parse(base_url, routes)

    for article in articles:
        quiz = generate_quiz(article)
        print(quiz)
        
        print("Enter your answers (end with 'END' on a new line):")
        user_answers = ""
        while True:
            line = input()
            if line.strip().upper() == "END":
                break
            user_answers += line + "\n"
        
        grade = grade_answers(user_answers, article)
        print(f"Your grade: {grade}")

if __name__ == "__main__":
    main()
