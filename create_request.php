<?php
/**
 * Create Emergency Blood Request API
 * LifeFlow Blood Donation App
 */

require_once 'db.php';

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, "Method not allowed", null, 405);
}

$data = getPostData();

// Validate required fields
$requiredFields = ['patient_id', 'blood_group', 'units', 'hospital_name', 'hospital_address', 'urgency'];
$missing = validateRequired($data, $requiredFields);
if (!empty($missing)) {
    sendResponse(false, "Missing required fields: " . implode(', ', $missing), null, 400);
}

try {
    $conn = getConnection();
    $conn->beginTransaction();

    // 1. Create Tables if they don't exist (Safety check for development)
    $conn->exec("
        CREATE TABLE IF NOT EXISTS blood_requests (
            request_id INT AUTO_INCREMENT PRIMARY KEY,
            patient_id INT NOT NULL,
            blood_group VARCHAR(5) NOT NULL,
            units INT NOT NULL,
            hospital_name VARCHAR(100) NOT NULL,
            hospital_address TEXT NOT NULL,
            urgency VARCHAR(20) NOT NULL,
            reason TEXT,
            status VARCHAR(20) DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (patient_id) REFERENCES users(user_id)
        );
    ");

    $conn->exec("
        CREATE TABLE IF NOT EXISTS notifications (
            notification_id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            title VARCHAR(100) NOT NULL,
            message TEXT NOT NULL,
            type VARCHAR(20) DEFAULT 'general',
            reference_id INT,
            is_read BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(user_id)
        );
    ");

    // 2. Insert the Request
    $stmt = $conn->prepare("
        INSERT INTO blood_requests 
        (patient_id, blood_group, units, hospital_name, hospital_address, urgency, reason) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ");

    $stmt->execute([
        $data['patient_id'],
        $data['blood_group'],
        $data['units'],
        $data['hospital_name'],
        $data['hospital_address'],
        $data['urgency'],
        $data['reason'] ?? null
    ]);

    $requestId = $conn->lastInsertId();

    // 3. Find Matching Donors
    // Assuming donor_profiles has a 'blood_group' column and users table has 'fcm_token' for Push Notifications (future)
    // For now, we just create in-app notifications

    $targetBloodGroup = $data['blood_group'];

    // Logic for compatible blood groups could go here, for now strictly matching
    $stmtDonors = $conn->prepare("
        SELECT u.user_id 
        FROM users u
        JOIN donor_profiles dp ON u.user_id = dp.user_id
        WHERE u.role = 'donor' 
        AND u.status = 'active'
        AND dp.blood_group = ?
        AND u.user_id != ? 
    ");
    // Don't notify the requester if they happen to be a donor too (unlikely flow but possible)

    $stmtDonors->execute([$targetBloodGroup, $data['patient_id']]);
    $donors = $stmtDonors->fetchAll(PDO::FETCH_COLUMN);

    // 4. Create Notifications
    if (!empty($donors)) {
        $notifyStmt = $conn->prepare("
            INSERT INTO notifications (user_id, title, message, type, reference_id)
            VALUES (?, ?, ?, 'emergency_request', ?)
        ");

        $title = "Emergency: $targetBloodGroup Needed!";
        $message = "Urgent request for {$data['units']} units at {$data['hospital_name']}. Can you help?";

        foreach ($donors as $donorId) {
            $notifyStmt->execute([$donorId, $title, $message, $requestId]);
        }
    }

    $conn->commit();

    sendResponse(true, "Request created successfully", [
        'request_id' => $requestId,
        'notified_donors_count' => count($donors)
    ]);

} catch (Exception $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    sendResponse(false, "Failed to create request: " . $e->getMessage(), null, 500);
}
?>