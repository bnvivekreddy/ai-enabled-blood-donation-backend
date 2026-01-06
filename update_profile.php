<?php
/**
 * Update User Profile API
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
    $conn->beginTransaction();

    switch ($role) {
        case 'donor':
            updateDonorProfile($conn, $userId, $data);
            break;
        case 'patient':
            updatePatientProfile($conn, $userId, $data);
            break;
        case 'hospital':
            updateHospitalProfile($conn, $userId, $data);
            break;
        default:
            throw new Exception("Invalid role");
    }

    $conn->commit();
    sendResponse(true, "Profile updated successfully");

} catch (Exception $e) {
    if (isset($conn)) {
        $conn->rollBack();
    }
    sendResponse(false, "Failed to update profile: " . $e->getMessage(), null, 500);
}

function updateDonorProfile($conn, $userId, $data)
{
    $fields = [];
    $values = [];

    $allowedFields = ['full_name', 'phone', 'weight', 'address', 'city', 'state', 'pincode', 'emergency_contact'];

    foreach ($allowedFields as $field) {
        if (isset($data[$field])) {
            $fields[] = "$field = ?";
            $values[] = sanitize($data[$field]);
        }
    }

    if (empty($fields)) {
        return;
    }

    $values[] = $userId;
    $sql = "UPDATE donor_profiles SET " . implode(', ', $fields) . " WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->execute($values);
}

function updatePatientProfile($conn, $userId, $data)
{
    $fields = [];
    $values = [];

    $allowedFields = ['full_name', 'phone', 'address', 'city', 'state', 'pincode', 'emergency_contact', 'medical_history'];

    foreach ($allowedFields as $field) {
        if (isset($data[$field])) {
            $fields[] = "$field = ?";
            $values[] = sanitize($data[$field]);
        }
    }

    if (empty($fields)) {
        return;
    }

    $values[] = $userId;
    $sql = "UPDATE patient_profiles SET " . implode(', ', $fields) . " WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->execute($values);
}

function updateHospitalProfile($conn, $userId, $data)
{
    $fields = [];
    $values = [];

    $allowedFields = ['hospital_name', 'contact_person', 'contact_phone', 'address', 'city', 'state', 'pincode', 'website', 'operating_hours'];

    foreach ($allowedFields as $field) {
        if (isset($data[$field])) {
            $fields[] = "$field = ?";
            $values[] = sanitize($data[$field]);
        }
    }

    if (empty($fields)) {
        return;
    }

    $values[] = $userId;
    $sql = "UPDATE hospital_profiles SET " . implode(', ', $fields) . " WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->execute($values);
}
?>