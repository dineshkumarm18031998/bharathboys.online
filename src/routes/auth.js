const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const router = express.Router();
const prisma = new PrismaClient();

// Register
router.post('/register', async (req, res) => {
  try {
    const { storeName, ownerName, mobile, password, address, lang } = req.body;

    if (!storeName || !ownerName || !mobile || !password) {
      return res.status(400).json({ error: 'All fields required' });
    }

    const exists = await prisma.store.findUnique({ where: { mobile } });
    if (exists) return res.status(400).json({ error: 'Mobile already registered' });

    const hashedPassword = await bcrypt.hash(password, 10);

    const store = await prisma.store.create({
      data: { storeName, ownerName, mobile, password: hashedPassword, address, lang: lang || 'en' }
    });

    const token = jwt.sign(
      { storeId: store.id, storeName: store.storeName, ownerName: store.ownerName, mobile: store.mobile, lang: store.lang },
      process.env.JWT_SECRET,
      { expiresIn: '365d' }
    );

    res.json({
      token,
      store: { id: store.id, storeName: store.storeName, ownerName: store.ownerName, mobile: store.mobile, address: store.address, lang: store.lang }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { mobile, password } = req.body;

    const store = await prisma.store.findUnique({ where: { mobile } });
    if (!store) return res.status(401).json({ error: 'Invalid credentials' });

    const valid = await bcrypt.compare(password, store.password);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign(
      { storeId: store.id, storeName: store.storeName, ownerName: store.ownerName, mobile: store.mobile, lang: store.lang },
      process.env.JWT_SECRET,
      { expiresIn: '365d' }
    );

    res.json({
      token,
      store: { id: store.id, storeName: store.storeName, ownerName: store.ownerName, mobile: store.mobile, address: store.address, lang: store.lang }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  }
});

module.exports = router;
