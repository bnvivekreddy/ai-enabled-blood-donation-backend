<?php
/**
 * Download User Data API
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

    // Get basic user account data
    $stmt = $conn->prepare("SELECT user_id, email, role, status, created_at, last_login FROM users WHERE user_id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user) {
        sendResponse(false, "User not found", null, 404);
    }

    // Get detailed profile data
    $profile = null;
    $rewards = null;

    switch ($role) {
        case 'donor':
            // Fetch Profile
            $stmt = $conn->prepare("SELECT * FROM donor_profiles WHERE user_id = ?");
            $stmt->execute([$userId]);
            $profile = $stmt->fetch();

            // Fetch Rewards
            if ($profile) {
                $stmt = $conn->prepare("SELECT * FROM donor_rewards WHERE donor_id = ?");
                $stmt->execute([$profile['donor_id']]);
                $rewards = $stmt->fetch();
            }
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

    // Prepare full data package
    $fullData = [
        'account_info' => $user,
        'profile_details' => $profile,
        'rewards_and_badges' => $rewards,
        'export_date' => date('Y-m-d H:i:s')
    ];

    sendResponse(true, "Data retrieved successfully", $fullData);

} catch (Exception $e) {
    sendResponse(false, "Failed to download data: " . $e->getMessage(), null, 500);
}
?>