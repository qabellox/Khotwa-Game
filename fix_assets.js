const { removeBackground } = require('@imgly/background-removal-node');
const fs = require('fs');
const path = require('path');

// Runner image: JPG -> PNG with white background removal
const runnerInput = path.join('khotwa', 'assets', 'generated', 'sprites', 'runner.jpg');
const runnerOutput = path.join('khotwa', 'assets', 'generated', 'sprites', 'runner.png');

// Start button image: JPG -> PNG with white background removal
const btnInput = path.join('khotwa', 'assets', 'generated', 'ui', 'start-button.jpg');
const btnOutput = path.join('khotwa', 'assets', 'generated', 'ui', 'start-button.png');

// Remove background from runner image
removeBackground(runnerInput, { type: 'white' })
  .then(result => {
    console.log('Runner background removed');
    const output = fs.createWriteStream(runnerOutput);
    result.pipe(output);
    output.on('finish', () => {
      console.log('Runner PNG saved: runner.png');
    });
  })
  .catch(err => {
    console.error('Error removing runner background:', err);
  });

// Remove background from start-button image
removeBackground(btnInput, { type: 'white' })
  .then(result => {
    console.log('Button background removed');
    const output = fs.createWriteStream(btnOutput);
    result.pipe(output);
    output.on('finish', () => {
      console.log('Button PNG saved: start-button.png');
    });
  })
  .catch(err => {
    console.error('Error removing button background:', err);
  });