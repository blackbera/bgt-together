import { useState, useEffect } from 'react';

export function CountdownTimer() {
  const [timeLeft, setTimeLeft] = useState({
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  const getNextSunday = () => {
    const now = new Date();
    const nextSunday = new Date(now);
    nextSunday.setDate(now.getDate() + (7 - now.getDay()));
    nextSunday.setHours(23, 59, 59, 999); // Set to end of Sunday (23:59:59.999)
    return nextSunday;
  };

  useEffect(() => {
    const calculateTimeLeft = () => {
      const now = new Date();
      let targetDate = getNextSunday();
      
      // If we're past the target, get next week's Sunday
      if (now > targetDate) {
        targetDate = getNextSunday();
      }

      const difference = targetDate.getTime() - now.getTime();

      setTimeLeft({
        days: Math.floor(difference / (1000 * 60 * 60 * 24)),
        hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
        minutes: Math.floor((difference / 1000 / 60) % 60),
        seconds: Math.floor((difference / 1000) % 60)
      });
    };

    calculateTimeLeft(); // Initial calculation
    const timer = setInterval(calculateTimeLeft, 1000);

    return () => clearInterval(timer);
  }, []);

  return (
    <div className="flex flex-col items-center">
      <h2 className="text-xl font-bold mb-4 bg-gradient-to-r from-amber-200 to-yellow-400 bg-clip-text text-transparent">
        Next BGT Lottery Ending
      </h2>
      <div className="flex justify-center gap-8 text-white">
        <div className="flex flex-col items-center">
          <div className="text-5xl font-bold bg-black/30 rounded-lg p-4 min-w-[100px]">
            {timeLeft.days.toString().padStart(2, '0')}
          </div>
          <span className="text-sm mt-2">DAYS</span>
        </div>
        <div className="flex flex-col items-center">
          <div className="text-5xl font-bold bg-black/30 rounded-lg p-4 min-w-[100px]">
            {timeLeft.hours.toString().padStart(2, '0')}
          </div>
          <span className="text-sm mt-2">HOURS</span>
        </div>
        <div className="flex flex-col items-center">
          <div className="text-5xl font-bold bg-black/30 rounded-lg p-4 min-w-[100px]">
            {timeLeft.minutes.toString().padStart(2, '0')}
          </div>
          <span className="text-sm mt-2">MINUTES</span>
        </div>
        <div className="flex flex-col items-center">
          <div className="text-5xl font-bold bg-black/30 rounded-lg p-4 min-w-[100px]">
            {timeLeft.seconds.toString().padStart(2, '0')}
          </div>
          <span className="text-sm mt-2">SECONDS</span>
        </div>
      </div>
    </div>
  );
} 