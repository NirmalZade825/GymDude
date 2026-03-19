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
  waterGoal: { type: Number, default: 3.0 },
  gender: { type: String, default: 'Male' },
  activityLevel: { type: Number, default: 1.2 },
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

// Define WorkoutLog Schema
const workoutLogSchema = new mongoose.Schema({
  email: { type: String, required: true },
  exerciseName: { type: String, required: true },
  muscleGroup: { type: String, required: true },
  level: { type: String, required: true },
  date: { type: String, required: true } // format: YYYY-MM-DD
})

const WorkoutLog = mongoose.model('WorkoutLog', workoutLogSchema)

app.get('/', (req, res) => {
  res.send('GymDude API - Hello World!')
})

// Function to calculate BMI
function calculateBMI(weightKg, heightMeters) {
    if (typeof weightKg !== 'number' || typeof heightMeters !== 'number') {
        throw new Error('Weight and height must be numbers.');
    }
    if (weightKg <= 0 || heightMeters <= 0) {
        throw new Error('Weight and height must be positive values.');
    }

    const bmi = weightKg / (heightMeters ** 2);
    return parseFloat(bmi.toFixed(2)); // Round to 2 decimal places
}

// Function to classify BMI
function classifyBMI(bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi >= 18.5 && bmi < 24.9) return 'Normal weight';
    if (bmi >= 25 && bmi < 29.9) return 'Overweight';
    return 'Obese';
}

function calculateBMR(weight, height, age, gender) {
  let bmr = (10 * weight) + (6.25 * height) - (5 * age);
  if ((gender || 'male').toLowerCase() === 'male') {
    bmr += 5;
  } else {
    bmr -= 161;
  }
  return bmr;
}

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
          waterGoal: user.waterGoal,
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
  const { email, fullName, age, weight, height, gender, activityLevel } = req.body

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
        gender,
        activityLevel,
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
          fullName: user.fullName,
          age: user.age,
          weight: user.weight,
          height: user.height,
          gender: user.gender,
          activityLevel: user.activityLevel,
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
  const { email, targetCalories, targetProtein, waterGoal } = req.body

  if (!email) {
    return res.status(400).json({ success: false, message: 'Email is required' })
  }

  try {
    const user = await User.findOneAndUpdate(
      { email },
      { targetCalories, targetProtein, waterGoal },
      { new: true }
    )

    if (user) {
      res.status(200).json({
        success: true,
        message: 'Goals updated successfully',
        data: {
          targetCalories: user.targetCalories,
          targetProtein: user.targetProtein,
          waterGoal: user.waterGoal
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

// Log Workout API
app.post('/log-workout', async (req, res) => {
  const { email, exerciseName, muscleGroup, level, date } = req.body;

  if (!email || !exerciseName || !date) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }

  try {
    const newWorkout = new WorkoutLog({
      email, exerciseName, muscleGroup, level, date
    });
    await newWorkout.save();

    res.status(201).json({ success: true, message: 'Workout logged successfully', log: newWorkout });
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

// Get Daily Workout API
app.get('/daily-workout/:email/:date', async (req, res) => {
  const { email, date } = req.params;

  try {
    const logs = await WorkoutLog.find({ email, date });

    res.status(200).json({
      success: true,
      data: {
        count: logs.length,
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

    // Calculate approx current weight
    let currentWeight = user.weight || 70; // fallback
    const heightCm = user.height || 175; // fallback
    const heightM = heightCm / 100;
    
    if (user.age && user.gender && user.activityLevel) {
       const bmr = calculateBMR(currentWeight, heightCm, user.age, user.gender);
       const dailyRequired = bmr * user.activityLevel;
       const totalRequired = dailyRequired * 7;
       const totalEaten = nutritionJourney.reduce((sum, val) => sum + val, 0);
       
       const calorieDiff = totalEaten - totalRequired;
       const weightChange = calorieDiff / 7700; // approx 1kg = 7700 kcal
       currentWeight += weightChange;
    }

    const bmi = calculateBMI(currentWeight, heightM);
    const bmiCategory = classifyBMI(bmi);

    res.status(200).json({
      success: true,
      data: {
        streakDays,
        bmi: bmi,
        bmiCategory: bmiCategory,
        adjustedWeight: parseFloat(currentWeight.toFixed(2)),
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

// Comprehensive Nutrition Database for Gym Goers (Global)
const nutritionDB = {
  // Meats & Poultry (grams)
  'chicken breast': { calories: 165, protein: 31, carbs: 0, fats: 3.6, unit: 'grams', baseAmount: 100 },
  'grilled chicken': { calories: 165, protein: 31, carbs: 0, fats: 3.6, unit: 'grams', baseAmount: 100 },
  'lean beef': { calories: 250, protein: 26, carbs: 0, fats: 15, unit: 'grams', baseAmount: 100 },
  'steak': { calories: 271, protein: 25, carbs: 0, fats: 19, unit: 'grams', baseAmount: 100 },
  'turkey breast': { calories: 135, protein: 30, carbs: 0, fats: 1, unit: 'grams', baseAmount: 100 },
  'pork chop (lean)': { calories: 197, protein: 27, carbs: 0, fats: 9, unit: 'grams', baseAmount: 100 },
  // Fish & Seafood (grams)
  'salmon': { calories: 208, protein: 20, carbs: 0, fats: 13, unit: 'grams', baseAmount: 100 },
  'tuna (canned)': { calories: 132, protein: 28, carbs: 0, fats: 1, unit: 'grams', baseAmount: 100 },
  'tilapia': { calories: 96, protein: 20, carbs: 0, fats: 1.7, unit: 'grams', baseAmount: 100 },
  'shrimp': { calories: 99, protein: 24, carbs: 0.2, fats: 0.3, unit: 'grams', baseAmount: 100 },
  // Carbs / Starches (grams)
  'white rice': { calories: 130, protein: 2.7, carbs: 28, fats: 0.3, unit: 'grams', baseAmount: 100 },
  'brown rice': { calories: 111, protein: 2.6, carbs: 23, fats: 0.9, unit: 'grams', baseAmount: 100 },
  'sweet potato': { calories: 86, protein: 1.6, carbs: 20, fats: 0.1, unit: 'grams', baseAmount: 100 },
  'potato': { calories: 77, protein: 2, carbs: 17, fats: 0.1, unit: 'grams', baseAmount: 100 },
  'oats': { calories: 389, protein: 16.9, carbs: 66.3, fats: 6.9, unit: 'grams', baseAmount: 100 },
  'pasta': { calories: 131, protein: 5, carbs: 25, fats: 1.1, unit: 'grams', baseAmount: 100 },
  'quinoa': { calories: 120, protein: 4.4, carbs: 21, fats: 1.9, unit: 'grams', baseAmount: 100 },
  'bread (whole wheat)': { calories: 247, protein: 13, carbs: 41, fats: 3.4, unit: 'grams', baseAmount: 100 },
  // Eggs & Dairy (quantity & ml & grams)
  'whole egg': { calories: 78, protein: 6.3, carbs: 0.6, fats: 5.3, unit: 'quantity', baseAmount: 1 },
  'egg white': { calories: 17, protein: 3.6, carbs: 0.2, fats: 0.1, unit: 'quantity', baseAmount: 1 },
  'greek yogurt': { calories: 59, protein: 10, carbs: 3.6, fats: 0.4, unit: 'grams', baseAmount: 100 },
  'cottage cheese': { calories: 98, protein: 11, carbs: 3.4, fats: 4.3, unit: 'grams', baseAmount: 100 },
  'milk (whole)': { calories: 61, protein: 3.2, carbs: 4.8, fats: 3.3, unit: 'ml', baseAmount: 100 },
  'milk (skim)': { calories: 34, protein: 3.4, carbs: 5, fats: 0.1, unit: 'ml', baseAmount: 100 },
  'cheese (cheddar)': { calories: 402, protein: 25, carbs: 1.3, fats: 33, unit: 'grams', baseAmount: 100 },
  // Fats & Nuts (grams)
  'peanut butter': { calories: 588, protein: 25, carbs: 20, fats: 50, unit: 'grams', baseAmount: 100 },
  'almond butter': { calories: 614, protein: 21, carbs: 19, fats: 56, unit: 'grams', baseAmount: 100 },
  'almonds': { calories: 579, protein: 21, carbs: 22, fats: 50, unit: 'grams', baseAmount: 100 },
  'walnuts': { calories: 654, protein: 15, carbs: 14, fats: 65, unit: 'grams', baseAmount: 100 },
  'olive oil': { calories: 884, protein: 0, carbs: 0, fats: 100, unit: 'ml', baseAmount: 100 },
  'avocado': { calories: 160, protein: 2, carbs: 8.5, fats: 14.7, unit: 'grams', baseAmount: 100 },
  'avocado (whole)': { calories: 322, protein: 4, carbs: 17, fats: 29, unit: 'quantity', baseAmount: 1 },
  // Fruits (quantity & grams)
  'banana': { calories: 105, protein: 1.3, carbs: 27, fats: 0.3, unit: 'quantity', baseAmount: 1 },
  'apple': { calories: 95, protein: 0.5, carbs: 25, fats: 0.3, unit: 'quantity', baseAmount: 1 },
  'orange': { calories: 62, protein: 1.2, carbs: 15, fats: 0.2, unit: 'quantity', baseAmount: 1 },
  'strawberries': { calories: 32, protein: 0.7, carbs: 7.7, fats: 0.3, unit: 'grams', baseAmount: 100 },
  'blueberries': { calories: 57, protein: 0.7, carbs: 14.5, fats: 0.3, unit: 'grams', baseAmount: 100 },
  // Vegetables (grams)
  'broccoli': { calories: 34, protein: 2.8, carbs: 6.6, fats: 0.4, unit: 'grams', baseAmount: 100 },
  'spinach': { calories: 23, protein: 2.9, carbs: 3.6, fats: 0.4, unit: 'grams', baseAmount: 100 },
  'asparagus': { calories: 20, protein: 2.2, carbs: 3.9, fats: 0.1, unit: 'grams', baseAmount: 100 },
  'carrots': { calories: 41, protein: 0.9, carbs: 9.6, fats: 0.2, unit: 'grams', baseAmount: 100 },
  // Supplements & Protein Powders (grams)
  'whey protein': { calories: 120, protein: 24, carbs: 3, fats: 1.5, unit: 'grams', baseAmount: 30 },
  'casein protein': { calories: 120, protein: 24, carbs: 4, fats: 1, unit: 'grams', baseAmount: 30 },
  'mass gainer': { calories: 380, protein: 25, carbs: 65, fats: 2, unit: 'grams', baseAmount: 100 },
  'creatine': { calories: 0, protein: 0, carbs: 0, fats: 0, unit: 'grams', baseAmount: 5 },
  // Fast Food & Cheat Meals (quantity)
  'pizza slice': { calories: 285, protein: 12, carbs: 36, fats: 10, unit: 'quantity', baseAmount: 1 },
  'burger': { calories: 540, protein: 34, carbs: 40, fats: 26, unit: 'quantity', baseAmount: 1 },
  'fried chicken': { calories: 320, protein: 14, carbs: 16, fats: 22, unit: 'quantity', baseAmount: 1 },
  'sushi roll (6 pieces)': { calories: 200, protein: 9, carbs: 38, fats: 1, unit: 'quantity', baseAmount: 1 },
  'ice cream (cup)': { calories: 207, protein: 3.5, carbs: 24, fats: 11, unit: 'quantity', baseAmount: 1 },
  // Drinks (ml)
  'protein shake': { calories: 120, protein: 24, carbs: 3, fats: 1.5, unit: 'ml', baseAmount: 300 },
  'coke': { calories: 42, protein: 0, carbs: 10.6, fats: 0, unit: 'ml', baseAmount: 100 },
  'pepsi': { calories: 41, protein: 0, carbs: 10.9, fats: 0, unit: 'ml', baseAmount: 100 },
  'orange juice': { calories: 45, protein: 0.7, carbs: 10.4, fats: 0.2, unit: 'ml', baseAmount: 100 },
  'apple juice': { calories: 46, protein: 0.1, carbs: 11.3, fats: 0.1, unit: 'ml', baseAmount: 100 },
  'black coffee': { calories: 2, protein: 0.2, carbs: 0, fats: 0.05, unit: 'ml', baseAmount: 100 },
  'latte': { calories: 43, protein: 2.8, carbs: 4.8, fats: 1.5, unit: 'ml', baseAmount: 100 },
  'green tea': { calories: 0, protein: 0, carbs: 0, fats: 0, unit: 'ml', baseAmount: 100 },
  'beer': { calories: 43, protein: 0.5, carbs: 3.6, fats: 0, unit: 'ml', baseAmount: 100 },
  'wine': { calories: 83, protein: 0.1, carbs: 2.6, fats: 0, unit: 'ml', baseAmount: 100 },
  'energy drink': { calories: 45, protein: 0, carbs: 11, fats: 0, unit: 'ml', baseAmount: 100 },
};

app.get('/nutrition', (req, res) => {
  const query = (req.query.query || '').toLowerCase().trim();

  if (!query) {
    return res.status(400).json({ success: false, message: 'Query parameter is required' });
  }

  const results = [];

  // Find all matches
  for (const [food, macros] of Object.entries(nutritionDB)) {
    if (food.includes(query)) {
      results.push({
        name: food.replace(/\b\w/g, c => c.toUpperCase()), // capitalize
        ...macros
      });
    }
  }

  // If we found matches, return them (up to 15 results to avoid massive lists)
  if (results.length > 0) {
    return res.status(200).json({ success: true, data: results.slice(0, 15) });
  }

  // Fallback defaults if not matched (just return an empty array or a generic suggestion)
  return res.status(200).json({
    success: true,
    data: [],
    message: 'No exact matches found.'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`✅ GymDude API is running on:`)
  console.log(`   - Local: http://localhost:${port}`)
  console.log(`   - Local Network: http://172.26.86.83:${port}`);
})
