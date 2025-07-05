// backend/routes/authRoutes.js
const express = require('express');
const {
  registerUser,
  loginUser,
  getUserProfile,
  updateUserProfile,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware'); // Nous allons créer ce middleware juste après

const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
// Les routes suivantes sont protégées et nécessitent un token valide
router.get('/profile', protect, getUserProfile);
router.put('/profile', protect, updateUserProfile);

module.exports = router;