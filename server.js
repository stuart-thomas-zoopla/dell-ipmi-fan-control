const express = require('express');
const Queue = require('bull');
const { exec } = require('child_process');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 3001;
const queue = new Queue('printQueue');

app.use(bodyParser.urlencoded({
    extended: false
}));
app.use(bodyParser.json());
app.use(express.static('/var/www/html/fan'));

queue.process(async (job) => {
    console.log(`Switching to ${job.data.text}`);
    exec(`${job.data.text}`, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing shell script: ${error.message}`);
            return;
        }
        if (stderr) {
            console.error(`Shell script stderr: ${stderr}`);
            return;
        }
        console.log(`Shell script output: ${stdout}`);
    });
});

app.post('/addJob', async (req, res) => {
    const text = req.body.text || 'bash auto.sh';
    await queue.add({
        text
    });
    res.send('Job added to queue!');
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);

    queue.on('ready', () => {
        console.log('Worker is ready!');
    });

    queue.on('error', (error) => {
        console.error('Queue error:', error);
    });

    queue.on('completed', (job) => {
        console.log(`Job ${job.id} completed`);
    });
});