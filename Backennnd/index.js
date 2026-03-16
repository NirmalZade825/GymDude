const express = require('express')
const mongoose = require('mongoose')
const app = express()
const port = 3000

// Middleware to parse JSON bodies
app.use(express.json())

// Connect to MongoDB
const MONGODB_URI = 'mongodb://127.0.0.1:27017/gymdude'
mongoose.connect(MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch(err => console.error('❌ MongoDB connection error:', err))

// Define User Schema
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  fullName: { type: String, default: '' },
  age: { type: Number },
  weight: { type: Number },
  height: { type: Number },
  targetCalories: { type: Number, default: 2500 },
  targetProtein: { type: Number, default: 180 },
  isProfileComplete: { type: Boolean, default: false }
})

const User = mongoose.model('User', userSchema)

// Define FoodLog Schema
const foodLogSchema = new mongoose.Schema({
  email: { type: String, required: true },
  foodName: { type: String, required: true },
  calories: { type: Number, required: true },
  protein: { type: Number, required: true },
  carbs: { type: Number, required: true },
  fats: { type: Number, required: true },
  servings: { type: Number, required: true },
  date: { type: String, required: true } // format: YYYY-MM-DD
})

const FoodLog = mongoose.model('FoodLog', foodLogSchema)

app.get('/', (req, res) => {
  res.send('GymDude API - Hello World!')
})

// Register API (for testing)
app.post('/register', async (req, res) => {
  const { email, password } = req.body

  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email and password are required' })
  }

  try {
    const existingUser = await User.findOne({ email })
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'User already exists' })
    }

    const newUser = new User({ email, password })
    await newUser.save()

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: { id: newUser._id, email: newUser.email }
    })
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message })
  }
})

// Login API with MongoDB
app.post('/login', async (req, res) => {
  const { email, password } = req.body

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email and password are required'
    })
  }

  try {
    const user = await User.findOne({ email, password })

    if (user) {
      return res.status(200).json({
        success: true,
        message: 'Login successful',
        user: {
          id: user._id,
          email: user.email,
          fullName: user.fullName,
          age: user.age,
          weight: user.weight,
          height: user.height,
          targetCalories: user.targetCalories,
          targetProtein: user.targetProtein,
          isProfileComplete: user.isProfileComplete
        }
      })
    } else {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      })
    }
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message })
  }
})

// Update Profile API (for onboarding)
app.post('/update-profile', async (req, res) => {
  const { email, fullName, age, weight, height } = req.body

  if (!email) {
    return res.status(400).json({ success: false, message: 'Email is required to update profile' })
  }

  try {
    const user = await User.findOneAndUpdate(
      { email },
      {
        fullName,
        age,
        weight,
        height,
        isProfileComplete: true
      },
      { new: true }
    )

    if (user) {
      res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        user: {
          id: user._id,
          email: user.email,
          isProfileComplete: user.isProfileComplete
        }
      })
    } else {
      res.status(404).json({ success: false, message: 'User not found' })
    }
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message })
  }
})

// Update Goals API (Calories and Protein)
app.post('/update-goals', async (req, res) => {
  const { email, targetCalories, targetProtein } = req.body

  if (!email) {
    return res.status(400).json({ success: false, message: 'Email is required' })
  }

  try {
    const user = await User.findOneAndUpdate(
      { email },
      { targetCalories, targetProtein },
      { new: true }
    )

    if (user) {
      res.status(200).json({
        success: true,
        message: 'Goals updated successfully',
        data: {
          targetCalories: user.targetCalories,
          targetProtein: user.targetProtein
        }
      })
    } else {
      res.status(404).json({ success: false, message: 'User not found' })
    }
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message })
  }
})

// Log Food API
app.post('/log-food', async (req, res) => {
  const { email, foodName, calories, protein, carbs, fats, servings, date } = req.body;

  if (!email || !foodName || calories == null || !date) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }

  try {
    const newLog = new FoodLog({
      email, foodName, calories, protein, carbs, fats, servings, date
    });
    await newLog.save();

    res.status(201).json({ success: true, message: 'Food logged successfully', log: newLog });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// Get Daily Nutrition API
app.get('/daily-nutrition/:email/:date', async (req, res) => {
  const { email, date } = req.params;

  try {
    const logs = await FoodLog.find({ email, date });

    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFats = 0;

    logs.forEach(log => {
      totalCalories += log.calories;
      totalProtein += log.protein;
      totalCarbs += log.carbs;
      totalFats += log.fats;
    });

    res.status(200).json({
      success: true,
      data: {
        totalCalories,
        totalProtein,
        totalCarbs,
        totalFats,
        logs
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// Get Progress Data API
app.get('/progress/:email', async (req, res) => {
  const { email } = req.params;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Get all unique dates where user logged food
    const logs = await FoodLog.find({ email }).select('date').lean();
    const activeDatesSet = new Set(logs.map(log => log.date));

    // Calculate streak
    let streakDays = 0;
    const formatDate = (date) => {
      const d = new Date(date);
      return d.toISOString().split('T')[0];
    };

    let checkDate = new Date();
    // If they haven't logged today, check if the streak continues from yesterday
    if (!activeDatesSet.has(formatDate(checkDate))) {
      checkDate.setDate(checkDate.getDate() - 1);
    }

    while (activeDatesSet.has(formatDate(checkDate))) {
      streakDays++;
      checkDate.setDate(checkDate.getDate() - 1);
    }

    // Calculate nutrition journey (last 7 days total calories)
    const nutritionJourney = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = formatDate(d);

      const dayLogs = await FoodLog.find({ email, date: dateStr }).select('calories').lean();
      const dayTotal = dayLogs.reduce((sum, log) => sum + log.calories, 0);
      nutritionJourney.push(dayTotal);
    }

    res.status(200).json({
      success: true,
      data: {
        streakDays,
        muscleMass: 42.5,
        bodyFat: 14.2,
        muscleMassChange: 1.2,
        bodyFatChange: -0.5,
        activeDates: Array.from(activeDatesSet),
        nutritionJourney,
        radarData: {
          labels: ['CHEST', 'ARMS', 'LEGS', 'BACK', 'CORE'],
          values: [0.8, 0.7, 0.9, 0.6, 0.5]
        }
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// Nutrition Database API (Mock Replacement)
const nutritionDB = {
  'pizza': { calories: 285, protein: 12, carbs: 36, fats: 10 },
  'burger': { calories: 540, protein: 34, carbs: 40, fats: 26 },
  'salad': { calories: 150, protein: 5, carbs: 10, fats: 10 },
  'sushi': { calories: 200, protein: 9, carbs: 38, fats: 1 },
  'steak': { calories: 679, protein: 62, carbs: 0, fats: 48 },
  'chicken': { calories: 335, protein: 38, carbs: 10, fats: 19 },
  'apple': { calories: 52, protein: 0.3, carbs: 14, fats: 0.2 },
  'banana': { calories: 105, protein: 1.3, carbs: 27, fats: 0.3 },
  'rice': { calories: 205, protein: 4.3, carbs: 44.5, fats: 0.4 },
  'egg': { calories: 78, protein: 6.3, carbs: 0.6, fats: 5.3 },
  'milk': { calories: 103, protein: 8, carbs: 12, fats: 2.4 },
  'oats': { calories: 389, protein: 16.9, carbs: 66.3, fats: 6.9 },
  'bread': { calories: 79, protein: 2.7, carbs: 15, fats: 1 },
  'pasta': { calories: 131, protein: 5, carbs: 25, fats: 1.1 },
  'ice cream': { calories: 207, protein: 3.5, carbs: 24, fats: 11 },
  'eggs scrambled': { calories: 91, protein: 6.7, carbs: 1.1, fats: 7 },
  'grilled chicken': { calories: 165, protein: 31, carbs: 0, fats: 3.6 },
  'caesar salad': { calories: 180, protein: 7, carbs: 10, fats: 14 },
  'orange juice': { calories: 45, protein: 0.7, carbs: 10.4, fats: 0.2 },
  'apple juice': { calories: 46, protein: 0.1, carbs: 11.3, fats: 0.1 },
  'coke': { calories: 139, protein: 0, carbs: 35, fats: 0 },
  'pepsi': { calories: 150, protein: 0, carbs: 41, fats: 0 },
  'coffee': { calories: 2, protein: 0.1, carbs: 0, fats: 0 },
  'tea': { calories: 1, protein: 0, carbs: 0.2, fats: 0 },
  'black coffee': { calories: 2, protein: 0.2, carbs: 0, fats: 0.05 },
  'latte': { calories: 67, protein: 3.5, carbs: 5.1, fats: 3.7 },
  'cappuccino': { calories: 56, protein: 3.4, carbs: 4.8, fats: 2.8 },
  'green tea': { calories: 0, protein: 0, carbs: 0, fats: 0 },
  'beer': { calories: 153, protein: 1.6, carbs: 12.6, fats: 0 },
  'wine': { calories: 83, protein: 0.1, carbs: 2.6, fats: 0 },
  'whiskey': { calories: 250, protein: 0, carbs: 0, fats: 0 },
  'vodka': { calories: 231, protein: 0, carbs: 0, fats: 0 },
  'energy drink': { calories: 110, protein: 0, carbs: 28, fats: 0 },
  'protein shake': { calories: 120, protein: 24, carbs: 3, fats: 1.5 },
  'lemonade': { calories: 40, protein: 0.1, carbs: 10, fats: 0.1 },
  'coconut water': { calories: 19, protein: 0.7, carbs: 3.7, fats: 0.2 },
  'smoothie': { calories: 50, protein: 1, carbs: 12, fats: 0.5 },
};

app.get('/nutrition', (req, res) => {
  const query = (req.query.query || '').toLowerCase();

  if (!query) {
    return res.status(400).json({ success: false, message: 'Query parameter is required' });
  }

  // Find partial match
  for (const [food, macros] of Object.entries(nutritionDB)) {
    if (query.includes(food)) {
      return res.status(200).json({ success: true, data: macros });
    }
  }

  // Fallback defaults if not matched
  return res.status(200).json({
    success: true,
    data: { calories: 250, protein: 10, carbs: 30, fats: 10 },
    message: 'Exact match not found, returning fallback data.'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`✅ GymDude API is running on:`)
  console.log(`   - Local: http://localhost:${port}`)
  console.log(`   - Local Network: http://172.26.86.83:${port}`);
})
