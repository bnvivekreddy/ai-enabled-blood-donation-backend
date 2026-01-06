<?php
/**
 * Delete Account API
 * LifeFlow Blood Donation App
 */

require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, "Method not allowed", null, 405);
}

$data = getPostData();

$missing = validateRequired($data, ['user_id']);
if (!empty($missing)) {
    sendResponse(false, "Missing required fields: user_id", null, 400);
}

$userId = (int) $data['user_id'];

try {
    $conn = getConnection();
    $conn->beginTransaction();

    // 1. Get role to know which profile table to target (optional, but good for cleanup if no FK cascade)
    $stmt = $conn->prepare("SELECT role FROM users WHERE user_id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if ($user) {
        $role = $user['role'];

        // 2. Delete from specific profile tables
        if ($role === 'donor') {
            // Get donor_id for rewards deletion if needed
            $stmt = $conn->prepare("SELECT donor_id FROM donor_profiles WHERE user_id = ?");
            $stmt->execute([$userId]);
            $donor = $stmt->fetch();

            if ($donor) {
                $conn->prepare("DELETE FROM donor_rewards WHERE donor_id = ?")->execute([$donor['donor_id']]);
            }
            $conn->prepare("DELETE FROM donor_profiles WHERE user_id = ?")->execute([$userId]);
        } elseif ($role === 'patient') {
            $conn->prepare("DELETE FROM patient_profiles WHERE user_id = ?")->execute([$userId]);
        } elseif ($role === 'hospital') {
            $conn->prepare("DELETE FROM hospital_profiles WHERE user_id = ?")->execute([$userId]);
        }
    }

    // 3. Delete from main users table
    $stmt = $conn->prepare("DELETE FROM users WHERE user_id = ?");
    $deleted = $stmt->execute([$userId]);

    if ($deleted) {
        $conn->commit();
        sendResponse(true, "Account deleted successfully");
    } else {
        $conn->rollBack();
        sendResponse(false, "Failed to delete account", null, 500);
    }

} catch (Exception $e) {
    if (isset($conn)) {
        $conn->rollBack();
    }
    sendResponse(false, "Error deleting account: " . $e->getMessage(), null, 500);
}
?>