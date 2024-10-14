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

public function main() returns error? {
    io:println("Welcome to the Package Delivery Management CLI!");

    while (true) {
        displayMenuOptions();
        string option = io:readln("Enter your option: ");

        match option {
            "1" => {
                error|http:Response result = addDeliveryRequest();
                if result is error {
                    io:println("Error adding delivery request");
                } else {
                    io:println("Delivery request added successfully");
                }
            }

            "2" => {
                error|http:Response result = getPackageStatus();
                if result is error {
                    io:println("Error retrieving package status");
                } else {
                    io:println("Package Status: ");
                    io:println(result.getJsonPayload());
                }
            }

            "3" => {
                error|http:Response result = getAvailability();
                if result is error {
                    io:println("Error checking availability");
                } else {
                    io:println("Availability Check: ");
                    io:println(result.getJsonPayload());
                }
            }

            "0" => {
                // Exit the CLI
                break;
            }

            _ => {
                io:println("Invalid option");
            }
        }
    }
}

// Function to add a new delivery request
function addDeliveryRequest() returns error|http:Response {
    string customerName = check io:readln("Enter customer name: ");
    string customerContact = check io:readln("Enter customer contact (e.g., johndoe@example.com): ");
    string fromTown = check io:readln("Enter pickup town: ");
    string toTown = check io:readln("Enter destination town: ");
    string pickupDate = check io:readln("Enter pickup date (YYYY-MM-DD): ");
    string pickupSlot = check io:readln("Enter pickup slot (e.g., 6): ");
    string deliveryType = check io:readln("Enter delivery type (e.g., International, Normal , Express): ");
    
    // Create the delivery request payload
    map<string> requestPayload = {
        customerName: customerName,
        customerContact: customerContact,
        fromTown: fromTown,
        toTown: toTown,
        pickupDate: pickupDate,
        pickupSlot: pickupSlot,
        deliveryType: deliveryType
    };

    // Create and set up the HTTP request
    http:Request request = new;
    json jsonBody = requestPayload.toJson();
    request.setPayload(jsonBody, "application/json");
    
    return deliveryClient->post("/request", request);
}


// Function to retrieve package status by package ID
function getPackageStatus() returns error|http:Response {
    string packageId = check io:readln("Enter package ID: ");
    
    // Construct the query URL using the packageId as a query parameter
    string url = "/packageStatus?packageId=" + packageId;

    // Make the GET request using the constructed URL
    return deliveryClient->get(url);
}


// Function to check availability for a specific town and date
function getAvailability() returns error|http:Response {
    string town = check io:readln("Enter town: ");
    string date = check io:readln("Enter date (YYYY-MM-DD): ");
    string slot = check io:readln("Enter slot (e.g., Slot_1): "); // Prompt for slot input

    // Construct the query URL
    string url = "/availabilityCheck?town=" + town + "&date=" + date + "&slot=" + slot; // Include slot in the URL

    // Make the GET request
    return deliveryClient->get(url);
}
