// backend/models/FigurineType.js
const mongoose = require("mongoose");

const figurineTypeSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true, // Les noms de type doivent être uniques (ex: "Infanterie", "Cavalerie")
    trim: true,
  },
});

const FigurineType = mongoose.model("FigurineType", figurineTypeSchema);

module.exports = FigurineType;