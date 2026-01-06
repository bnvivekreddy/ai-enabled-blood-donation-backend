<?php
/**
 * User Registration API
 * LifeFlow Blood Donation App
 * 
 * Handles registration for donors, patients, and hospitals
 */

require_once 'db.php';

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, "Method not allowed", null, 405);
}

$data = getPostData();

// Validate required user fields
$requiredFields = ['email', 'password', 'role'];
$missing = validateRequired($data, $requiredFields);

if (!empty($missing)) {
    sendResponse(false, "Missing required fields: " . implode(', ', $missing), null, 400);
}

// Validate role
$validRoles = ['donor', 'patient', 'hospital'];
if (!in_array($data['role'], $validRoles)) {
    sendResponse(false, "Invalid role. Must be: donor, patient, or hospital", null, 400);
}

// Validate email format
$email = sanitize($data['email']);
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendResponse(false, "Invalid email format", null, 400);
}

// Validate password length
if (strlen($data['password']) < 6) {
    sendResponse(false, "Password must be at least 6 characters", null, 400);
}

try {
    $conn = getConnection();
    
    // Check if email already exists
    $stmt = $conn->prepare("SELECT user_id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    
    if ($stmt->fetch()) {
        sendResponse(false, "Email already registered", null, 409);
    }
    
    // Hash password
    $passwordHash = password_hash($data['password'], PASSWORD_BCRYPT);
    
    // Begin transaction
    $conn->beginTransaction();
    
    // Insert user
    $stmt = $conn->prepare("INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)");
    $stmt->execute([$email, $passwordHash, $data['role']]);
    $userId = $conn->lastInsertId();
    
    // Create profile based on role
    $profileId = null;
    
    switch ($data['role']) {
        case 'donor':
            $profileId = createDonorProfile($conn, $userId, $data);
            break;
        case 'patient':
            $profileId = createPatientProfile($conn, $userId, $data);
            break;
        case 'hospital':
            $profileId = createHospitalProfile($conn, $userId, $data);
            break;
    }
    
    // Create donor rewards if donor
    if ($data['role'] === 'donor' && $profileId) {
        $stmt = $conn->prepare("INSERT INTO donor_rewards (donor_id) VALUES (?)");
        $stmt->execute([$profileId]);
    }
    
    $conn->commit();
    
    sendResponse(true, "Registration successful", [
        'user_id' => (int)$userId,
        'profile_id' => (int)$profileId,
        'role' => $data['role'],
        'email' => $email
    ], 201);
    
} catch (Exception $e) {
    if (isset($conn)) {
        $conn->rollBack();
    }
    sendResponse(false, "Registration failed: " . $e->getMessage(), null, 500);
}

/**
 * Create Donor Profile
 */
function createDonorProfile($conn, $userId, $data) {
    $required = ['full_name', 'blood_group', 'gender', 'age', 'phone'];
    $missing = validateRequired($data, $required);
    
    if (!empty($missing)) {
        throw new Exception("Missing donor fields: " . implode(', ', $missing));
    }
    
    $stmt = $conn->prepare("
        INSERT INTO donor_profiles 
        (user_id, full_name, blood_group, gender, age, phone, weight, latitude, longitude, address, city, state, pincode)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $stmt->execute([
        $userId,
        sanitize($data['full_name']),
        sanitize($data['blood_group']),
        sanitize($data['gender']),
        (int)$data['age'],
        sanitize($data['phone']),
        isset($data['weight']) ? (float)$data['weight'] : null,
        isset($data['latitude']) ? (float)$data['latitude'] : null,
        isset($data['longitude']) ? (float)$data['longitude'] : null,
        isset($data['address']) ? sanitize($data['address']) : null,
        isset($data['city']) ? sanitize($data['city']) : null,
        isset($data['state']) ? sanitize($data['state']) : null,
        isset($data['pincode']) ? sanitize($data['pincode']) : null
    ]);
    
    return $conn->lastInsertId();
}

/**
 * Create Patient Profile
 */
function createPatientProfile($conn, $userId, $data) {
    $required = ['full_name', 'blood_group', 'gender', 'age', 'phone'];
    $missing = validateRequired($data, $required);
    
    if (!empty($missing)) {
        throw new Exception("Missing patient fields: " . implode(', ', $missing));
    }
    
    $stmt = $conn->prepare("
        INSERT INTO patient_profiles 
        (user_id, full_name, blood_group, gender, age, phone, latitude, longitude, address, city, state, pincode, emergency_contact, medical_history)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $stmt->execute([
        $userId,
        sanitize($data['full_name']),
        sanitize($data['blood_group']),
        sanitize($data['gender']),
        (int)$data['age'],
        sanitize($data['phone']),
        isset($data['latitude']) ? (float)$data['latitude'] : null,
        isset($data['longitude']) ? (float)$data['longitude'] : null,
        isset($data['address']) ? sanitize($data['address']) : null,
        isset($data['city']) ? sanitize($data['city']) : null,
        isset($data['state']) ? sanitize($data['state']) : null,
        isset($data['pincode']) ? sanitize($data['pincode']) : null,
        isset($data['emergency_contact']) ? sanitize($data['emergency_contact']) : null,
        isset($data['medical_history']) ? sanitize($data['medical_history']) : null
    ]);
    
    return $conn->lastInsertId();
}

/**
 * Create Hospital Profile
 */
function createHospitalProfile($conn, $userId, $data) {
    $required = ['hospital_name', 'registration_number', 'license_number', 'license_expiry_date', 
                 'contact_person', 'contact_email', 'contact_phone', 'latitude', 'longitude', 
                 'address', 'city', 'state', 'pincode'];
    $missing = validateRequired($data, $required);
    
    if (!empty($missing)) {
        throw new Exception("Missing hospital fields: " . implode(', ', $missing));
    }
    
    $stmt = $conn->prepare("
        INSERT INTO hospital_profiles 
        (user_id, hospital_name, registration_number, license_number, license_expiry_date, 
         blood_bank_license, contact_person, contact_email, contact_phone, 
         latitude, longitude, address, city, state, pincode, website, operating_hours)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $stmt->execute([
        $userId,
        sanitize($data['hospital_name']),
        sanitize($data['registration_number']),
        sanitize($data['license_number']),
        sanitize($data['license_expiry_date']),
        isset($data['blood_bank_license']) ? sanitize($data['blood_bank_license']) : null,
        sanitize($data['contact_person']),
        sanitize($data['contact_email']),
        sanitize($data['contact_phone']),
        (float)$data['latitude'],
        (float)$data['longitude'],
        sanitize($data['address']),
        sanitize($data['city']),
        sanitize($data['state']),
        sanitize($data['pincode']),
        isset($data['website']) ? sanitize($data['website']) : null,
        isset($data['operating_hours']) ? sanitize($data['operating_hours']) : null
    ]);
    
    return $conn->lastInsertId();
}
?>
