// backend/controllers/authController.js
const User = require('../models/User');
const jwt = require('jsonwebtoken'); // Pour générer les tokens JWT
// Assurez-vous que bcryptjs est importé si votre modèle User l'utilise pour matchPassword
// const bcrypt = require('bcryptjs'); 

// Fonction utilitaire pour générer un token JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '1h', // Le token expirera après 1 heure
  });
};

// @desc      Enregistrer un nouvel utilisateur
// @route     POST /api/auth/register
// @access    Public
const registerUser = async (req, res) => {
  const { username, email, password } = req.body;

  try {
    // Vérifier si l'utilisateur existe déjà
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'L\'utilisateur avec cet email existe déjà' });
    }

    user = await User.findOne({ username });
    if (user) {
      return res.status(400).json({ message: 'Ce nom d\'utilisateur est déjà pris' });
    }

    // Créer un nouvel utilisateur
    user = await User.create({
      username,
      email,
      password, // Le hachage est fait par le middleware `pre('save')` du modèle User
    });

    if (user) {
      res.status(201).json({
        _id: user._id,
        username: user.username,
        email: user.email,
        token: generateToken(user._id), // Générer un token pour le nouvel utilisateur
        role: user.role // Assurez-vous d'inclure le rôle si votre modèle User le définit
      });
    } else {
      res.status(400).json({ message: 'Données utilisateur invalides' });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur lors de l\'inscription' });
  }
};

// @desc      Authentifier un utilisateur et obtenir un token
// @route     POST /api/auth/login
// @access    Public
const loginUser = async (req, res) => {
  console.log('Contenu de req.body au début de loginUser:', req.body);
  // >>> Correction ici: Utilisez 'email' directement, car c'est ce que le frontend envoie <<<
  const { email, password } = req.body; 

  try {
    console.log('Tentative de connexion pour l\'email:', email); 
    // Recherchez l'utilisateur par son email
    const user = await User.findOne({ email }); 

    // Vérifiez si l'utilisateur existe ET si le mot de passe correspond
    // Assurez-vous que 'user.matchPassword' est une méthode de votre modèle User
    // qui utilise bcrypt.compare (si votre mot de passe est haché)
    if (user && (await user.matchPassword(password))) {
      res.json({
        _id: user._id,
        username: user.username,
        email: user.email, 
        token: generateToken(user._id),
        role: user.role // Important pour le frontend pour gérer les permissions
      });
    } else {
      // Message générique pour des raisons de sécurité (ne pas révéler si l'email existe ou non)
      res.status(401).json({ message: 'Email ou mot de passe invalide' }); 
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur lors de la connexion' });
  }
};

// @desc      Obtenir le profil de l'utilisateur connecté
// @route     GET /api/auth/profile
// @access    Private (nécessite un token)
const getUserProfile = async (req, res) => {
  // L'objet `req.user` est ajouté par le middleware d'authentification
  const user = await User.findById(req.user._id).select('-password'); // Exclut le mot de passe

  if (user) {
    res.json({
      _id: user._id,
      username: user.username,
      email: user.email,
      role: user.role, // Incluez le rôle ici aussi
      createdAt: user.createdAt,
    });
  } else {
    res.status(404).json({ message: 'Utilisateur non trouvé' });
  }
};

// @desc      Mettre à jour le profil de l'utilisateur
// @route     PUT /api/auth/profile
// @access    Private
const updateUserProfile = async (req, res) => {
  const user = await User.findById(req.user._id);

  if (user) {
    user.username = req.body.username || user.username;
    user.email = req.body.email || user.email;

    if (req.body.password) {
      user.password = req.body.password; // Le middleware pre-save hachera le nouveau mot de passe
    }

    const updatedUser = await user.save();

    res.json({
      _id: updatedUser._id,
      username: updatedUser.username,
      email: updatedUser.email,
      token: generateToken(updatedUser._id), // Générer un nouveau token si l'utilisateur est mis à jour
      role: updatedUser.role // Incluez le rôle
    });
  } else {
    res.status(404).json({ message: 'Utilisateur non trouvé' });
  }
};

module.exports = {
  registerUser,
  loginUser,
  getUserProfile,
  updateUserProfile,
};
