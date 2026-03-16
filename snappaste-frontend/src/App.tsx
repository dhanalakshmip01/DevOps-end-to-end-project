import { BrowserRouter, Route, Routes } from 'react-router-dom';
import CreatePaste from './components/CreatePaste';
import ViewPaste from './components/ViewPaste';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<CreatePaste />} />
        <Route path="/paste/:shortCode" element={<ViewPaste />} />
      </Routes>
    </BrowserRouter>
  );
}
