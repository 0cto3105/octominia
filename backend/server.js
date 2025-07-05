// backend/server.js
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const figurineRoutes = require('./routes/figurineRoutes'); // Importe les routes de figurines
const userRoutes = require('./routes/users');
const orderRoutes = require('./routes/orders'); // Nouvelle route
const factionRoutes = require('./routes/factions'); // Nouvelle route

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Connexion à la base de données MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('Connecté à MongoDB !'))
  .catch(err => console.error('Erreur de connexion à MongoDB :', err));

// Route de test simple (déjà là)
app.get('/', (req, res) => {
  res.send('API de gestion de stock de figurines - OK');
});

// --- Routes de l'API ---
app.use('/api/auth', authRoutes);         // Routes pour l'authentification
app.use('/api/figurines', figurineRoutes); // Nouvelles routes pour les figurines
app.use('/api/users', userRoutes);
app.use('/api/orders', orderRoutes); // Nouvelle
app.use('/api/factions', factionRoutes); // Nouvelle

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
});