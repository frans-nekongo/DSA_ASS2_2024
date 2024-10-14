import ballerina/http;
import ballerina/io;

// Import the auto-generated Client class for package delivery requests
http:Client deliveryClient = check new("http://localhost:9090");

function displayMenuOptions() {
    io:println("Please select an option:");
    io:println("1. Add a new request");
    io:println("2. Retrieve package status by package ID");
    io:println("3. Check availability for a specific town and date");
    io:println("0. Exit");
}

