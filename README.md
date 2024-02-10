# Dungeon Quiz Generator and Grader

## Overview

This Python application is designed for generating quizzes based on dungeon guides from various online sources, and then grading user responses. It leverages OpenAI's GPT-4 model for creating insightful, class-specific questions and assessing answers. The application is ideal for players who want to test their knowledge of dungeons in a fun and interactive way.

## Features

- **Quiz Generation:** Automatically generates quizzes based on dungeon guide articles.
- **Answer Grading:** Utilizes OpenAI's GPT-4 model to grade user responses based on the content of the dungeon guides.
- **Multiline Input Support:** Allows users to input answers spanning multiple lines for detailed responses.
- **Diverse Dungeon Support:** Can fetch and parse dungeon guides from specified URLs, allowing for a wide range of quiz topics.
- **WoW Classic Addon (In Development):** One day will allow users to take quizzes and share results with players around them.

## Prerequisites

- Python 3.x
- Internet access for API calls
- OpenAI API key

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/juntshc/roachiq.git
   cd roachiq
   ```

2. Install the required packages:
   ```
   pip install requests beautifulsoup4 openai
   ```

3. Set up your OpenAI API key as an environment variable:
   ```
   export OPENAI_API_KEY='your-api-key'
   ```

## Usage

Run the application:

```bash
python app.py
```

Follow the on-screen instructions to view the quiz and enter your answers. Type 'END' on a new line to submit your answers for grading.

## Configuration

To customize the dungeons for which quizzes are generated, modify the `routes` list in the `main` function with the desired endpoints.

## Contributing

Contributions to improve the app are welcome. Please adhere to the following steps:

1. Fork the repository.
2. Create a new branch for your feature (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a pull request.

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Tom J - tjuntshc@gmail.com

Project Link: [https://github.com/your-username/dungeon-quiz-app](https://github.com/juntshc/roachiq)

---

Remember to replace placeholders like `your-username`, `your-api-key`, and `email@example.com` with your actual information. You can also add more sections if necessary, such as 'Acknowledgements', 'Known Issues', or 'Future Plans'.
