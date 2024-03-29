let pdfDoc = null,
    pageNum = 1,
    pageRendering = false,
    pageNumPending = null;

const canvas = document.createElement('canvas');
let ctx = canvas.getContext('2d');
// const url = './path/to/your/document.pdf';

document.getElementById('pdf-viewer').appendChild(canvas);

const pageInfo = document.getElementById('page-info');

function renderPage(num) {
    pageRendering = true;
    pdfDoc.getPage(num).then(function(page) {
        var viewport = page.getViewport({ scale: 1.5 }); 
        canvas.height = viewport.height;
        canvas.width = viewport.width;

        var renderContext = {
            canvasContext: ctx,
            viewport: viewport
        };
        var renderTask = page.render(renderContext);
        renderTask.promise.then(function() {
            pageRendering = false;
            pageInfo.textContent = `Page: ${num}/${pdfDoc.numPages}`;
            if (pageNumPending !== null) {
                renderPage(pageNumPending);
                pageNumPending = null;
            }
        }).catch(function(error) {
            console.log('Error during page rendering: ', error);
        });
    }).catch(function(error) {
        console.log('Error fetching the page: ', error);
    });
}

// Upload and render the PDF document
document.getElementById('upload-button').addEventListener('click', function() {
    const file = document.getElementById('file-input').files[0];
    if (file && file.type === 'application/pdf') {
        const fileReader = new FileReader();
        fileReader.onload = function() {
            const pdfData = this.result; 

            fetch('/api/upload', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/pdf' 
                },
                body: pdfData
            })
            .then(response => response.json()) // Assuming processed data is JSON
            .then(data => {
                // Update the frontend based on the received data
                // Example: Display the extracted text
                document.getElementById('prompt-input').value = data.extractedText;
            }) 
            .catch(error => console.error('Error:', error)); 
        };
        fileReader.readAsArrayBuffer(file);
    } else {
        alert('Please upload a valid PDF file.');
    }
});

// Event listener for the submit button
document.getElementById('submit-prompt').addEventListener('click', function() {
    const promptContent = document.getElementById('prompt-input').value.trim();
    if (promptContent) {
        fetch('/api/ask', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ prompt: promptContent })
        })
        .then(response => response.json())
        .then(data => console.log(data))
        .catch(error => console.error('Error:', error));
    } else {
        alert('Please enter a prompt.');
    }
});

// Navigation buttons
document.getElementById('prev-page').addEventListener('click', function() {
    if (pageNum > 1) {
        pageNum--;
        renderPage(pageNum);
    }
});
document.getElementById('next-page').addEventListener('click', function() {
    if (pdfDoc !== null && pageNum < pdfDoc.numPages) {
        pageNum++;
        renderPage(pageNum);
    }
});
