const express = require('express');
const { PrismaClient } = require('@prisma/client');
const auth = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

router.get('/', auth, async (req, res) => {
  try {
    const products = await prisma.product.findMany({ where: { storeId: req.storeId }, orderBy: { createdAt: 'desc' } });
    res.json(products);
  } catch (err) { res.status(500).json({ error: 'Failed to fetch products' }); }
});

router.post('/', auth, async (req, res) => {
  try {
    const { name, totalQty, rentPerDay, deposit, image } = req.body;
    if (!name || !totalQty || !rentPerDay) return res.status(400).json({ error: 'Name, quantity and rent required' });
    const product = await prisma.product.create({
      data: { name, totalQty: parseInt(totalQty), rentPerDay: parseFloat(rentPerDay), deposit: parseFloat(deposit) || 0, image, storeId: req.storeId }
    });
    res.json(product);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Failed to create product' }); }
});

router.put('/:id', auth, async (req, res) => {
  try {
    const { name, totalQty, rentPerDay, deposit, image } = req.body;
    const product = await prisma.product.update({
      where: { id: req.params.id },
      data: { name, totalQty: parseInt(totalQty), rentPerDay: parseFloat(rentPerDay), deposit: parseFloat(deposit) || 0, ...(image && { image }) }
    });
    res.json(product);
  } catch (err) { res.status(500).json({ error: 'Failed to update product' }); }
});

router.delete('/:id', auth, async (req, res) => {
  try { await prisma.product.delete({ where: { id: req.params.id } }); res.json({ success: true }); }
  catch (err) { res.status(500).json({ error: 'Failed to delete product' }); }
});

module.exports = router;
