<?php
/**
 * Get Notifications API
 * LifeFlow Blood Donation App
 */

require_once 'db.php';

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, "Method not allowed", null, 405);
}

$data = getPostData();

// Validate required fields
if (!isset($data['user_id'])) {
    sendResponse(false, "Missing user_id", null, 400);
}

$userId = (int) $data['user_id'];

try {
    $conn = getConnection();

    $stmt = $conn->prepare("
        SELECT * FROM notifications 
        WHERE user_id = ? 
        ORDER BY created_at DESC 
        LIMIT 50
    ");

    $stmt->execute([$userId]);
    $notifications = $stmt->fetchAll();

    sendResponse(true, "Notifications fetched", $notifications);

} catch (Exception $e) {
    sendResponse(false, "Failed to fetch notifications: " . $e->getMessage(), null, 500);
}
?>