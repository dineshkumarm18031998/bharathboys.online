const express = require('express');
const { PrismaClient } = require('@prisma/client');
const auth = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// Get all bookings for store
router.get('/', auth, async (req, res) => {
  try {
    const bookings = await prisma.booking.findMany({
      where: { storeId: req.storeId },
      include: { items: true, damages: true },
      orderBy: { createdAt: 'desc' }
    });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
});

// Get single booking
router.get('/:id', auth, async (req, res) => {
  try {
    const booking = await prisma.booking.findUnique({
      where: { id: req.params.id },
      include: { items: true, damages: true }
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    res.json(booking);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch booking' });
  }
});

// Create booking
router.post('/', auth, async (req, res) => {
  try {
    const { cName, cMob, cAddr, notes, eventType, startDate, items } = req.body;
    if (!cName || !cMob || !items?.length) {
      return res.status(400).json({ error: 'Customer name, mobile and items required' });
    }

    const today = new Date().toISOString().split('T')[0];

    const booking = await prisma.booking.create({
      data: {
        date: today,
        cName,
        cMob,
        cAddr,
        notes,
        eventType,
        startDate: startDate || today,
        storeId: req.storeId,
        items: {
          create: items.map(i => ({
            name: i.name,
            qty: parseInt(i.qty),
            rate: parseFloat(i.rate),
            image: i.image || null
          }))
        }
      },
      include: { items: true, damages: true }
    });
    res.json(booking);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create booking' });
  }
});

// Update booking (return date, payment, etc)
router.put('/:id', auth, async (req, res) => {
  try {
    const { returnDate, totalDays, subtotal, discount, totalAmount, paid, paidAmount, returned, actualReturnDate, isVip } = req.body;

    const booking = await prisma.booking.update({
      where: { id: req.params.id },
      data: {
        ...(returnDate !== undefined && { returnDate }),
        ...(totalDays !== undefined && { totalDays: parseInt(totalDays) }),
        ...(subtotal !== undefined && { subtotal: parseFloat(subtotal) }),
        ...(discount !== undefined && { discount: parseFloat(discount) }),
        ...(totalAmount !== undefined && { totalAmount: parseFloat(totalAmount) }),
        ...(paid !== undefined && { paid }),
        ...(paidAmount !== undefined && { paidAmount: parseFloat(paidAmount) }),
        ...(returned !== undefined && { returned }),
        ...(actualReturnDate !== undefined && { actualReturnDate }),
        ...(isVip !== undefined && { isVip })
      },
      include: { items: true, damages: true }
    });
    res.json(booking);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update booking' });
  }
});

// Delete booking
router.delete('/:id', auth, async (req, res) => {
  try {
    await prisma.booking.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete booking' });
  }
});

module.exports = router;
