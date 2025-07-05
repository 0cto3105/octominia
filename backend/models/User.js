// backend/models/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs'); // Pour le hachage des mots de passe

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true, // Chaque nom d'utilisateur doit être unique
    trim: true,   // Supprime les espaces blancs inutiles
    minlength: 3
  },
  email: {
    type: String,
    required: true,
    unique: true, // Chaque email doit être unique
    trim: true,
    lowercase: true, // Convertit l'email en minuscules
    match: [/.+@.+\..+/, 'Veuillez utiliser une adresse email valide'] // Validation simple de l'email
  },
  password: {
    type: String,
    required: true,
    minlength: 6 // Longueur minimale du mot de passe
  },
  createdAt: {
    type: Date,
    default: Date.now // Date de création du compte
  },
  // --- MODIFICATION ICI POUR LES RÔLES ---
  role: {
    type: String,
    required: true,
    enum: ['guest', 'user', 'admin'], // Ajout de 'guest' et 'admin'
    default: 'user' // Le rôle par défaut reste 'user' pour les inscriptions classiques
  }
});

// --- MIDDLEWARE Mongoose ---
// Pré-sauvegarde : hacher le mot de passe avant de sauvegarder l'utilisateur
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) { // Vérifie si le mot de passe a été modifié
    return next();
  }
  const salt = await bcrypt.genSalt(10); // Génère un "sel" (salt) pour le hachage
  this.password = await bcrypt.hash(this.password, salt); // Hache le mot de passe
  next();
});

// --- MÉTHODE Mongoose ---
// Méthode pour comparer le mot de passe entré avec le mot de passe haché
userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

const User = mongoose.model('User', userSchema);

module.exports = User;