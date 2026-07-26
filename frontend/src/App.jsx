import React from 'react';
import { GoogleReCaptchaProvider } from 'react-google-recaptcha-v3';
import './App.css';
import ImageCompressor from './components/ImageCompressor';

function App() {
  const recaptchaSiteKey = process.env.REACT_APP_RECAPTCHA_SITE_KEY;

  return (
    <GoogleReCaptchaProvider reCaptchaKey={recaptchaSiteKey} language="en">
      <div className="app">
        <div className="container">
          <header className="header">
            <h1>🖼️ ShrinkIt</h1>
            <p>Compress your images effortlessly</p>
          </header>
          <ImageCompressor />
        </div>
      </div>
    </GoogleReCaptchaProvider>
  );
}

export default App;
