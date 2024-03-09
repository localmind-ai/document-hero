const express = require('express');
const multer = require('multer');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static('app'));

const upload = multer({ storage: multer.memoryStorage() });

// Hypothetical PDF processing function
function processPDF(pdfBuffer) {
    // TODO: Replace with more sophisticated PDF processing logic
    // Example: Extract text from the PDF
    const processedData = extractTextFromPDF(pdfBuffer);
    return processedData;
}


app.post('/api/ask', async (req, res) => {
    const userPrompt = req.body.prompt;
    // The API request body format
    const data = {
        model: "gpt-3.5-turbo",
        messages: [
            { "role": "system", "content": "You are a helpful assistant." },
            { "role": "user", "content": userPrompt }
        ]
    };
    try {
        const response = await axios.post('https://api.openai.com/v1/chat/completions', data, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
            }
        });
        res.json({ reply: response.data.choices[0].message.content });
    } catch (error) {
        console.error('Error:', error.message);
        res.status(500).json({ message: error.message });
    }
});

app.post('/api/upload', upload.single('pdfFile'), async (req, res) => {
    const pdfBuffer = req.file.buffer;

    try {
        const processedData = await processPDF(pdfBuffer);
        res.json(processedData); // Send the processed data to the frontend 

    } catch (error) {
        console.error('Error:', error.message);
        res.status(500).json({ message: "Error processing PDF" }); 
    }
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});