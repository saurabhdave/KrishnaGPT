# KrishnaGPT SwiftUI iOS App
Krishna GPT: This SwiftUI MVVM based app, influenced by the teachings of the Bhagavad Gita, provides answers with a spiritual perspective to help you uncover hidden truths.
Get your answers in 6 different languages English, Hindi, French, German, Madarin and Spanish.

This project offers an AI-powered online Bhagavad Gita experience. Based on the 18 chapters and 700 shlokas, it provides moral, strength, discipline, and spiritual guidance to help alleviate Arjuna's troubles.

### Check Out app video on YouTube: https://www.youtube.com/shorts/LKj8Ch9f_us


<img src="https://user-images.githubusercontent.com/7702191/217727798-66866075-82ab-40bb-bc20-0861d69b4724.jpg" width="15%"></img> 
<img src="https://user-images.githubusercontent.com/7702191/217727725-7cc3a52a-1554-4d5d-9477-6f9194559fdd.jpg" width="15%"></img>
<img src="https://user-images.githubusercontent.com/7702191/217727743-badb8f8b-a34d-4671-8d28-d45b57d7b940.jpg" width="15%"></img>
<img src="https://user-images.githubusercontent.com/7702191/217727778-1255cab8-3e07-4424-9906-3d81df556346.jpg" width="15%"></img> 
<img src="https://user-images.githubusercontent.com/7702191/217727789-04ae3de6-1f7a-401b-8276-11510b3ff8dd.jpg" width="15%"></img> 

## UPDATE

The leaked model had been removed by OpenAI. Until a new model is found, i'll use the default text-davinci-003

## Supported Platforms

- iOS 15 and above

## Requierements
- Xcode 14 
- Register for API key from [OpenAI](https://openai.com/api)
- Create API Key
- Paste API key in KrishnaGPTApp file where the ChatGPTAPI instance is declared

```swift
let api = ChatGPTAPI(apiKey: "API_KEY")
```

## How it works

This initiative employs the OpenAI GPT-3 API, specifically the text-davinci-003, in a streaming manner. It formulates a prompt based on the user's input and the desired format, then forwards it to the GPT-3 API. The received response is then streamed back to the app.
