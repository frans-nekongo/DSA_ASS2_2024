import ballerina/http;
import ballerina/io;

http:Client deliveryClient = check new("http://localhost:9090");

function displayMenuOptions() {
    io:println("Please select an option:");
    io:println("1. Check availability for a town and date");
    io:println("2. Submit a delivery request");
    io:println("3. Check package status by package ID");
    io:println("0. Exit");
}

public function main() returns error? {
    io:println("Welcome to the Package Delivery Management CLI!");

    while (true) {
        displayMenuOptions();
        string option = io:readln("Enter your option: ");

        match option {
            "1" => {
                error|http:Response result = checkAvailability();
                if result is error {
                    io:println("Error checking availability");
                } else {
                    io:println("Available Slots: ");
                    io:println(result.getJsonPayload());
                }
            }

            "2" => {
                error|http:Response result = submitDeliveryRequest();
                if result is error {
                    io:println("Error submitting delivery request");
                } else {
                    io:println("Delivery request submitted successfully");
                }
            }

            "3" => {
                error|http:Response result = checkPackageStatus();
                if result is error {
                    io:println("Error retrieving package status");
                } else {
                    io:println("Package Status: ");
                    io:println(result.getJsonPayload());
                }
            }

            "0" => {
                io:println("Exiting...");
                break;
            }

            _ => {
                io:println("Invalid option");
            }
        }
    }
}

function checkAvailability() returns error|http:Response {
    string town = check io:readln("Enter town name: ");
    string date = check io:readln("Enter date (YYYY-MM-DD): ");
    
    // Directly create the map with query parameters
    map<string|string[]> queryParams = {
        "town": [town],
        "date": [date]
    };

    // Use the map as a parameter for the get request
    return deliveryClient->get("/availabilityCheck", queryParams);
}

function submitDeliveryRequest() returns error|http:Response {
    string customerName = check io:readln("Enter customer name: ");
    string fromTown = check io:readln("Enter pickup town: ");
    string toTown = check io:readln("Enter destination town: ");
    string pickupDate = check io:readln("Enter pickup date (YYYY-MM-DD): ");
    string deliveryType = check io:readln("Enter delivery type (normal/express/international): ");

    map<string> requestPayload = {
        "customerName": customerName,
        "fromTown": fromTown,
        "toTown": toTown,
        "pickupDate": pickupDate,
        "deliveryType": deliveryType
    };

    http:Request request = new;
    json jsonBody = requestPayload.toJson();
    request.setPayload(jsonBody, "application/json");
    return deliveryClient->post("/request", request);
}

function checkPackageStatus() returns error|http:Response {
    string packageId = check io:readln("Enter package ID: ");
    
    // Directly create the map with query parameters
    map<string|string[]> queryParams = {
        "packageId": [packageId]
    };

    // Use the map as a parameter for the get request
    return deliveryClient->get("/packageStatus", queryParams);
}
