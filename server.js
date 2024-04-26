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

// Function to execute a shell script and return the output
function executeShellScript(scriptPath, callback) {
    exec(`bash ${scriptPath}`, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing shell script: ${error.message}`);
            return;
        }
        if (stderr) {
            console.error(`Shell script stderr: ${stderr}`);
            return;
        }
        callback(stdout.trim());
    });
}

// Function to execute the sensors command and extract the highest temperature value
function getSensorsData(callback) {
    exec('sensors', (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing command: ${error.message}`);
            return;
        }
        if (stderr) {
            console.error(`Command stderr: ${stderr}`);
            return;
        }
        callback(stdout.trim());
    });
}

// Function to extract the highest temperature value from the sensors output
function extractHighestTemperature(sensorsOutput) {
    const lines = sensorsOutput.split('\n');
    let highestTemp = -273;

    lines.forEach(line => {
        const tempMatch = line.match(/\+([0-9.]+)/);
        if (tempMatch) {
            const temp = parseFloat(tempMatch[1]);
            if (temp > highestTemp) {
                highestTemp = temp;
            }
        }
    });

    return highestTemp;
}

// Endpoint to retrieve the highest temperature value
app.get('/api/highestTemperature', (req, res) => {
    getSensorsData((output) => {
        const highestTemp = extractHighestTemperature(output);
        res.json({ highestTemperature: highestTemp });
    });
});

// Endpoint to retrieve the ambient temperature
app.get('/api/ambientTemperature', (req, res) => {
    executeShellScript('/var/www/html/fan/ambient_temp.sh', (output) => {
        const ambientTemp = parseInt(output);
        if (!isNaN(ambientTemp)) {
            res.json({ ambientTemperature: ambientTemp });
        } else {
            res.status(500).json({ error: 'Failed to parse ambient temperature' });
        }
    });
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