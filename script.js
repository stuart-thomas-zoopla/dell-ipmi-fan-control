const host = window.location.hostname;
console.log("Local IP Address:", host); 
const url = `http://${host}:3001/addJob`

document.addEventListener("DOMContentLoaded", function() {
    function sendPostRequest(body) {
        return fetch(url, {
            method: "POST",
            body: body,
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            }
        })
        .then(function(response) {
            if (response.ok) {
                console.log("POST request successful");
            } else {
                console.error("Error:", response.statusText);
            }
        })
        .catch(function(error) {
            console.error("Error:", error);
        });
    }

    function handleAutoButtonClick(event) {
        event.preventDefault();
        sendPostRequest("text=bash /var/www/html/fan/auto.sh");
    }

    function handleSubmitButtonClick(event) {
        event.preventDefault();
        var numberInput = document.getElementById("numberInput").value;
        var body = "text=bash /var/www/html/fan/manual.sh " + numberInput;
        sendPostRequest(body);
    }

    function handleRebootButtonClick(event) {
        event.preventDefault();
        sendPostRequest("text=reboot");
    }

    var autoButton = document.getElementById("autoBtn");
    autoButton.addEventListener("click", handleAutoButtonClick);

    var submitButton = document.getElementById("submit");
    submitButton.addEventListener("click", handleSubmitButtonClick);

    var autoButton = document.getElementById("rebootBtn");
    autoButton.addEventListener("click", handleRebootButtonClick);
});