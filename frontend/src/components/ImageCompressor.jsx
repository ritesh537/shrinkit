import React, { useState } from 'react';
import axios from 'axios';
import { useGoogleReCaptcha } from 'react-google-recaptcha-v3';
import '../styles/ImageCompressor.css';

const API_ENDPOINT = process.env.REACT_APP_API_ENDPOINT || 'http://localhost:3001';
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

export default function ImageCompressor() {
  const { executeRecaptcha } = useGoogleReCaptcha();

  const [file, setFile] = useState(null);
  const [originalSize, setOriginalSize] = useState(0);
  const [targetSize, setTargetSize] = useState(500);
  const [compressedSize, setCompressedSize] = useState(0);
  const [compressedImage, setCompressedImage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [step, setStep] = useState('upload'); // upload, compress, download
  const [visitorsCount, setVisitorsCount] = useState(0);

  // Fetch visitor count on mount
  React.useEffect(() => {
    fetchVisitorCount();
  }, []);

  const fetchVisitorCount = async () => {
    try {
      const response = await axios.get(`${API_ENDPOINT}/stats`);
      setVisitorsCount(response.data.visitors || 0);
    } catch (err) {
      console.log('Could not fetch visitor count');
    }
  };

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile) {
      const validTypes = ['image/jpeg', 'image/png', 'image/jpg'];
      if (!validTypes.includes(selectedFile.type)) {
        setError('Please upload JPG, JPEG, or PNG images only');
        return;
      }

      // Strict 10MB limit for server protection
      if (selectedFile.size > MAX_FILE_SIZE) {
        setError(`File size must be less than 10MB. Your file is ${(selectedFile.size / 1024 / 1024).toFixed(2)}MB`);
        return;
      }

      setFile(selectedFile);
      setOriginalSize(selectedFile.size);
      setStep('compress');
      setError('');
      setCompressedImage(null);
      setCompressedSize(0);
    }
  };

  const handleCompress = async () => {
    if (!file) {
      setError('Please select an image first');
      return;
    }

    if (targetSize <= 0) {
      setError('Target size must be greater than 0');
      return;
    }

    setLoading(true);
    setError('');

    try {
      // Get reCAPTCHA token
      const recaptchaToken = await executeRecaptcha('compress');

      const formData = new FormData();
      formData.append('file', file);
      formData.append('targetSize', targetSize);
      formData.append('recaptchaToken', recaptchaToken);

      const response = await axios.post(
        `${API_ENDPOINT}/compress`,
        formData,
        {
          headers: { 'Content-Type': 'multipart/form-data' },
          responseType: 'blob'
        }
      );

      const compressedBlob = response.data;
      const compressedUrl = URL.createObjectURL(compressedBlob);

      setCompressedImage(compressedUrl);
      setCompressedSize(compressedBlob.size);
      setStep('download');
    } catch (err) {
      let errorMsg = 'Error compressing image. Please try again.';

      if (err.response?.status === 403) {
        errorMsg = 'Verification failed. Please try again.';
      } else if (err.response?.status === 413) {
        errorMsg = err.response?.data?.error || 'File is too large. Maximum size is 10MB.';
      } else if (err.response?.data?.error) {
        errorMsg = err.response.data.error;
      }

      setError(errorMsg);
      console.error('Compression error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = () => {
    if (compressedImage) {
      const link = document.createElement('a');
      link.href = compressedImage;
      link.download = `${file.name.split('.')[0]}_compressed.${file.type.split('/')[1]}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  };

  const handleReset = () => {
    setFile(null);
    setOriginalSize(0);
    setTargetSize(500);
    setCompressedSize(0);
    setCompressedImage(null);
    setError('');
    setStep('upload');
  };

  const formatBytes = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
  };

  return (
    <div className="compressor">
      {/* Visitor Counter */}
      <div className="visitor-counter">
        👥 {visitorsCount.toLocaleString()} visitors
      </div>

      {/* Upload Step */}
      {step === 'upload' && (
        <div className="step upload-step">
          <div className="upload-area">
            <label htmlFor="file-input" className="file-label">
              <div className="upload-icon">📁</div>
              <p>Click to upload or drag and drop</p>
              <span className="upload-hint">JPG, JPEG or PNG (Max 10MB)</span>
            </label>
            <input
              id="file-input"
              type="file"
              onChange={handleFileChange}
              accept=".jpg,.jpeg,.png"
              className="file-input"
            />
          </div>
        </div>
      )}

      {/* Compress Step */}
      {step === 'compress' && (
        <div className="step compress-step">
          <div className="file-info">
            <div className="info-card">
              <span className="label">Original File</span>
              <span className="value">{formatBytes(originalSize)}</span>
            </div>
            <div className="arrow">→</div>
            <div className="info-card target">
              <span className="label">Target Size</span>
              <div className="target-input-group">
                <input
                  type="number"
                  min="1"
                  max="10000"
                  value={targetSize}
                  onChange={(e) => setTargetSize(parseInt(e.target.value) || 0)}
                  className="target-input"
                />
                <span className="unit">KB</span>
              </div>
            </div>
          </div>

          <div className="compression-ratio">
            <p>Compression: {Math.round((1 - targetSize * 1024 / originalSize) * 100)}%</p>
          </div>

          <div className="actions">
            <button
              onClick={handleCompress}
              disabled={loading}
              className="btn btn-primary"
            >
              {loading ? 'Compressing...' : 'Compress Image'}
            </button>
            <button
              onClick={handleReset}
              className="btn btn-secondary"
            >
              Change Image
            </button>
          </div>

          {error && <div className="error-message">{error}</div>}
        </div>
      )}

      {/* Download Step */}
      {step === 'download' && compressedImage && (
        <div className="step download-step">
          <div className="success-icon">✅</div>
          <h2>Compression Complete!</h2>

          <div className="size-comparison">
            <div className="size-item">
              <span className="size-label">Original</span>
              <span className="size-value">{formatBytes(originalSize)}</span>
            </div>
            <div className="size-item">
              <span className="size-label">Compressed</span>
              <span className="size-value">{formatBytes(compressedSize)}</span>
            </div>
            <div className="size-item highlight">
              <span className="size-label">Reduction</span>
              <span className="size-value">{Math.round((1 - compressedSize / originalSize) * 100)}%</span>
            </div>
          </div>

          <div className="image-preview">
            <img src={compressedImage} alt="Compressed" />
          </div>

          <div className="actions">
            <button
              onClick={handleDownload}
              className="btn btn-primary"
            >
              ⬇️ Download Compressed Image
            </button>
            <button
              onClick={handleReset}
              className="btn btn-secondary"
            >
              Compress Another Image
            </button>
          </div>
        </div>
      )}

      {error && step !== 'compress' && (
        <div className="error-message">{error}</div>
      )}
    </div>
  );
}
