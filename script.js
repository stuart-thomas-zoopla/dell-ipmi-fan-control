const host = window.location.hostname;
const url = `http://${host}:3001`;

document.addEventListener("DOMContentLoaded", function() {
    function fetchTemperatures() {
        fetchcpuTemperature();
        fetchAmbientTemperature();
    }

    function fetchcpuTemperature() {
        fetch(`${url}/api/cpuTemperature`)
            .then(response => response.json())
            .then(data => updateTemperature(data.cpuTemperature, 'cpuTemp'))
            .catch(error => console.error('Error fetching cpu temperature:', error));
    }

    function fetchAmbientTemperature() {
        fetch(`${url}/api/ambientTemperature`)
            .then(response => response.json())
            .then(data => updateTemperature(data.ambientTemperature, 'ambientTemp'))
            .catch(error => console.error('Error fetching ambient temperature:', error));
    }

    function updateTemperature(temperature, elementId) {
        const temperatureElement = document.getElementById(elementId);
        temperatureElement.textContent = `${temperature}  C`;

        temperatureElement.classList.remove('ambient-temp', 'high-ambient-temp', 'cpu-temp', 'high-cpu-temp');
        if (elementId === 'cpuTemp') {
            if (temperature >= 90) {
                temperatureElement.classList.add('high-cpu-temp');
            } else if (temperature >= 80) {
                temperatureElement.classList.add('cpu-temp');
            }
        } else if (elementId === 'ambientTemp') {
            if (temperature >= 35) {
                temperatureElement.classList.add('high-ambient-temp');
            } else if (temperature >= 30) {
                temperatureElement.classList.add('ambient-temp');
            }
        }
    }

    fetchTemperatures();

    setInterval(fetchTemperatures, 15000);
});
                