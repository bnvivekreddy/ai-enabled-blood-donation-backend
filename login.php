<?php
/**
 * User Login API
 * LifeFlow Blood Donation App
 */

require_once 'db.php';

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, "Method not allowed", null, 405);
}

$data = getPostData();

// Validate required fields
$missing = validateRequired($data, ['email', 'password']);
if (!empty($missing)) {
    sendResponse(false, "Missing required fields: " . implode(', ', $missing), null, 400);
}

$email = sanitize($data['email']);

try {
    $conn = getConnection();
    
    // Get user by email
    $stmt = $conn->prepare("
        SELECT user_id, email, password_hash, role, status 
        FROM users 
        WHERE email = ?
    ");
    $stmt->execute([$email]);
    $user = $stmt->fetch();
    
    if (!$user) {
        sendResponse(false, "Invalid email or password", null, 401);
    }
    
    // Check if account is active
    if ($user['status'] !== 'active') {
        sendResponse(false, "Account is " . $user['status'], null, 403);
    }
    
    // Verify password
    if (!password_verify($data['password'], $user['password_hash'])) {
        sendResponse(false, "Invalid email or password", null, 401);
    }
    
    // Update last login
    $stmt = $conn->prepare("UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = ?");
    $stmt->execute([$user['user_id']]);
    
    // Get profile data based on role
    $profile = getProfileByRole($conn, $user['user_id'], $user['role']);
    
    // Generate simple token (in production, use JWT)
    $token = bin2hex(random_bytes(32));
    
    sendResponse(true, "Login successful", [
        'user_id' => (int)$user['user_id'],
        'email' => $user['email'],
        'role' => $user['role'],
        'token' => $token,
        'profile' => $profile
    ]);
    
} catch (Exception $e) {
    sendResponse(false, "Login failed: " . $e->getMessage(), null, 500);
}

/**
 * Get profile data based on user role
 */
function getProfileByRole($conn, $userId, $role) {
    switch ($role) {
        case 'donor':
            $stmt = $conn->prepare("
                SELECT dp.*, dr.total_points, dr.current_level, dr.total_badges
                FROM donor_profiles dp
                LEFT JOIN donor_rewards dr ON dp.donor_id = dr.donor_id
                WHERE dp.user_id = ?
            ");
            break;
            
        case 'patient':
            $stmt = $conn->prepare("
                SELECT * FROM patient_profiles WHERE user_id = ?
            ");
            break;
            
        case 'hospital':
            $stmt = $conn->prepare("
                SELECT * FROM hospital_profiles WHERE user_id = ?
            ");
            break;
            
        default:
            return null;
    }
    
    $stmt->execute([$userId]);
    return $stmt->fetch();
}
?>
