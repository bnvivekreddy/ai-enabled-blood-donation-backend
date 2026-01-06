<?php
/**
 * Get User Profile API
 * LifeFlow Blood Donation App
 */

require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, "Method not allowed", null, 405);
}

$data = getPostData();

$missing = validateRequired($data, ['user_id', 'role']);
if (!empty($missing)) {
    sendResponse(false, "Missing required fields: " . implode(', ', $missing), null, 400);
}

$userId = (int) $data['user_id'];
$role = sanitize($data['role']);

try {
    $conn = getConnection();

    // Get user data
    $stmt = $conn->prepare("SELECT user_id, email, role, status, created_at FROM users WHERE user_id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user) {
        sendResponse(false, "User not found", null, 404);
    }

    // Get profile based on role
    $profile = null;

    switch ($role) {
        case 'donor':
            $stmt = $conn->prepare("
                SELECT dp.*, dr.total_points, dr.current_level, dr.total_badges
                FROM donor_profiles dp
                LEFT JOIN donor_rewards dr ON dp.donor_id = dr.donor_id
                WHERE dp.user_id = ?
            ");
            $stmt->execute([$userId]);
            $profile = $stmt->fetch();
            break;

        case 'patient':
            $stmt = $conn->prepare("SELECT * FROM patient_profiles WHERE user_id = ?");
            $stmt->execute([$userId]);
            $profile = $stmt->fetch();
            break;

        case 'hospital':
            $stmt = $conn->prepare("SELECT * FROM hospital_profiles WHERE user_id = ?");
            $stmt->execute([$userId]);
            $profile = $stmt->fetch();
            break;
    }

    sendResponse(true, "Profile retrieved successfully", [
        'user' => $user,
        'profile' => $profile
    ]);

} catch (Exception $e) {
    sendResponse(false, "Failed to get profile: " . $e->getMessage(), null, 500);
}
?>