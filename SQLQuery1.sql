CREATE DATABASE WeatherDB;
GO

USE WeatherDB;
CREATE TABLE Dim_Date (
    DateID INT IDENTITY(1,1) PRIMARY KEY,
    [Date] DATE UNIQUE,
    [Year] SMALLINT,
    [Month] TINYINT,
    [Day] TINYINT,
    Season NVARCHAR(20)
);

INSERT INTO Dim_Date ([Date], [Year], [Month], [Day], Season)
SELECT DISTINCT
    [Date],
    [Year],
    [Month],
    [Day],
    Season
FROM Weather_Raw;

CREATE TABLE Dim_City (
    CityID INT IDENTITY(1,1) PRIMARY KEY,
    City NVARCHAR(50),
    Latitude FLOAT,
    Longitude FLOAT
);
INSERT INTO Dim_City (City, Latitude, Longitude)
SELECT DISTINCT
    City,
    Latitude,
    Longitude
FROM Weather_Raw;

CREATE TABLE Fact_Weather (
    WeatherFactID INT IDENTITY(1,1) PRIMARY KEY,
    DateID INT,
    CityID INT,

    Temperature_Max FLOAT,
    Temperature_Min FLOAT,
    Temperature_Mean FLOAT,
    Apparent_Temperature FLOAT,
    Relative_Humidity FLOAT,
    Precipitation FLOAT,
    Wind_Speed FLOAT,
    Wind_Direction FLOAT,
    Surface_Pressure FLOAT,
    Cloud_Cover FLOAT,
    Sunshine_Duration FLOAT,
    Weather_Code TINYINT,

    FOREIGN KEY (DateID) REFERENCES Dim_Date(DateID),
    FOREIGN KEY (CityID) REFERENCES Dim_City(CityID)
);

INSERT INTO Fact_Weather
(
    DateID,
    CityID,
    Temperature_Max,
    Temperature_Min,
    Temperature_Mean,
    Apparent_Temperature,
    Relative_Humidity,
    Precipitation,
    Wind_Speed,
    Wind_Direction,
    Surface_Pressure,
    Cloud_Cover,
    Sunshine_Duration,
    Weather_Code
)
SELECT
    d.DateID,
    c.CityID,
    w.Temperature_Max,
    w.Temperature_Min,
    w.Temperature_Mean,
    w.Apparent_Temperature,
    w.Relative_Humidity,
    w.Precipitation,
    w.Wind_Speed,
    w.Wind_Direction,
    w.Surface_Pressure,
    w.Cloud_Cover,
    w.Sunshine_Duration,
    w.Weather_Code
FROM Weather_Raw w
INNER JOIN Dim_Date d
    ON w.[Date] = d.[Date]
INNER JOIN Dim_City c
    ON w.City = c.City
   AND w.Latitude = c.Latitude
   AND w.Longitude = c.Longitude;

   SELECT COUNT(*) AS RawRows FROM Weather_Raw;

SELECT COUNT(*) AS DateRows FROM Dim_Date;

SELECT COUNT(*) AS CityRows FROM Dim_City;

SELECT COUNT(*) AS FactRows FROM Fact_Weather;

SELECT @@SERVERNAME;

Go

--Insight 1: Best Time to Travel--
CREATE VIEW vw_BestTimeToTravel AS
SELECT
    c.City,
    d.Month,
    ROUND(AVG(f.Temperature_Mean),2) AS AvgTemperature,
    ROUND(AVG(f.Relative_Humidity),2) AS AvgHumidity,
    ROUND(AVG(f.Precipitation),2) AS AvgRain,
    ROUND(AVG(f.Sunshine_Duration),2) AS AvgSunshine
FROM Fact_Weather f
JOIN Dim_Date d
ON f.DateID=d.DateID
JOIN Dim_City c
ON f.CityID=c.CityID
GROUP BY
    c.City,
    d.Month;

--Insight 2: Holiday & Outdoor Feasibility Index
CREATE VIEW vw_OutdoorFeasibility AS
SELECT
    c.City,
    d.Month,

    ROUND(AVG(
        100
        - ABS(f.Temperature_Mean-24)*2
        - f.Relative_Humidity*0.25
        - f.Precipitation*3
        - f.Cloud_Cover*0.15
    ),2) AS OutdoorScore

FROM Fact_Weather f
JOIN Dim_Date d
ON f.DateID=d.DateID
JOIN Dim_City c
ON f.CityID=c.CityID

GROUP BY
c.City,
d.Month;

--Insight 3: Weather Comfort Score
CREATE VIEW vw_WeatherComfortScore AS

SELECT

c.City,

ROUND(AVG(

100
-ABS(f.Apparent_Temperature-23)*2
-f.Relative_Humidity*0.2
-f.Wind_Speed*0.4

),2)

AS ComfortScore

FROM Fact_Weather f

JOIN Dim_City c

ON f.CityID=c.CityID

GROUP BY c.City;


--Insight 4: Coastal Humidity vs Inland Dry Heat
CREATE VIEW vw_CoastalVsInland AS

SELECT

c.City,

ROUND(AVG(f.Relative_Humidity),2) AS AvgHumidity,

ROUND(AVG(f.Temperature_Mean),2) AS AvgTemperature

FROM Fact_Weather f

JOIN Dim_City c

ON f.CityID=c.CityID

GROUP BY c.City;

--Insight 5: Rainfall Exposure Ranking
CREATE VIEW vw_RainfallRanking AS

SELECT

c.City,

ROUND(SUM(f.Precipitation),2) AS TotalRain,

COUNT(

CASE

WHEN f.Precipitation>0

THEN 1

END

) AS RainyDays

FROM Fact_Weather f

JOIN Dim_City c

ON f.CityID=c.CityID

GROUP BY c.City;


--Insight 6: Heat Index / Apparent Temperature
CREATE VIEW vw_HeatIndexAnalysis AS
SELECT
    c.City,
    d.Month,
    ROUND(AVG(f.Temperature_Mean),2) AS AvgActualTemp,
    ROUND(AVG(f.Apparent_Temperature),2) AS AvgFeelsLike,
    ROUND(AVG(f.Apparent_Temperature - f.Temperature_Mean),2) AS HeatStress
FROM Fact_Weather f
JOIN Dim_Date d ON f.DateID=d.DateID
JOIN Dim_City c ON f.CityID=c.CityID
GROUP BY c.City,d.Month;

--Insight 7: Monthly Heatwave Detection
CREATE VIEW vw_MonthlyHeatwaveDetection AS
SELECT
    c.City,
    d.Year,
    d.Month,
    COUNT(*) AS HeatwaveDays
FROM Fact_Weather f
JOIN Dim_Date d ON f.DateID=d.DateID
JOIN Dim_City c ON f.CityID=c.CityID
WHERE f.Temperature_Max >= 40
GROUP BY
    c.City,
    d.Year,
    d.Month;

--Insight 8: Diurnal Temperature Range (DTR)
CREATE VIEW vw_DTR AS
SELECT
    c.City,
    d.Date,
    f.Temperature_Max,
    f.Temperature_Min,
    ROUND(f.Temperature_Max - f.Temperature_Min,2) AS DTR
FROM Fact_Weather f
JOIN Dim_Date d ON f.DateID=d.DateID
JOIN Dim_City c ON f.CityID=c.CityID;

--Insight 9: Thermal Volatility Index
CREATE VIEW vw_ThermalVolatility AS
SELECT
    c.City,
    d.Year,
    d.Month,
    ROUND(STDEV(f.Temperature_Mean),2) AS ThermalVolatility
FROM Fact_Weather f
JOIN Dim_Date d ON f.DateID=d.DateID
JOIN Dim_City c ON f.CityID=c.CityID
GROUP BY
    c.City,
    d.Year,
    d.Month;

--Insight 10: Extreme Weather Ranking
CREATE VIEW vw_ExtremeWeatherRanking AS
SELECT
    c.City,

    SUM(CASE WHEN f.Temperature_Max>=40 THEN 1 ELSE 0 END) AS VeryHotDays,

    SUM(CASE WHEN f.Precipitation>=10 THEN 1 ELSE 0 END) AS HeavyRainDays,

    SUM(CASE WHEN f.Wind_Speed>=30 THEN 1 ELSE 0 END) AS StrongWindDays,

    (
      SUM(CASE WHEN f.Temperature_Max>=40 THEN 1 ELSE 0 END)
      +
      SUM(CASE WHEN f.Precipitation>=10 THEN 1 ELSE 0 END)
      +
      SUM(CASE WHEN f.Wind_Speed>=30 THEN 1 ELSE 0 END)
    ) AS ExtremeScore

FROM Fact_Weather f
JOIN Dim_City c
ON f.CityID=c.CityID

GROUP BY c.City;

--Insight 11: Sudden Temperature Change Analysis
CREATE VIEW vw_SuddenTemperatureChange AS
WITH TempChanges AS
(
    SELECT
        c.City,
        d.Date,
        f.Temperature_Mean,

        LAG(f.Temperature_Mean) OVER
        (
            PARTITION BY c.City
            ORDER BY d.Date
        ) AS PreviousTemp

    FROM Fact_Weather f
    JOIN Dim_Date d
        ON f.DateID = d.DateID
    JOIN Dim_City c
        ON f.CityID = c.CityID
)

SELECT
    City,
    Date,
    Temperature_Mean,
    PreviousTemp,
    ROUND(ABS(Temperature_Mean - PreviousTemp),2) AS TempChange
FROM TempChanges;

--Insight 12: Most Variable Months
CREATE VIEW vw_MostVariableMonths AS

SELECT

    d.Month,

    ROUND(STDEV(f.Temperature_Mean),2) AS TemperatureVariation

FROM Fact_Weather f

JOIN Dim_Date d

ON f.DateID=d.DateID

GROUP BY d.Month;

--Insight 13: Most Stable Cities
CREATE VIEW vw_MostStableCities AS

SELECT

    c.City,

    ROUND(STDEV(f.Temperature_Mean),2) AS StabilityIndex

FROM Fact_Weather f

JOIN Dim_City c

ON f.CityID=c.CityID

GROUP BY c.City;

--Insight 14: Humidity vs Temperature Relationship
CREATE VIEW vw_HumidityVsTemperature AS

SELECT

    c.City,

    ROUND(AVG(f.Relative_Humidity),2) AS AvgHumidity,

    ROUND(AVG(f.Temperature_Mean),2) AS AvgTemperature,

    ROUND(AVG(f.Apparent_Temperature),2) AS AvgFeelsLike

FROM Fact_Weather f

JOIN Dim_City c

ON f.CityID=c.CityID

GROUP BY c.City;

--Insight 15: Seasonal Comparison
CREATE VIEW vw_SeasonalComparison AS

SELECT

    d.Season,

    ROUND(AVG(f.Temperature_Mean),2) AS AvgTemperature,

    ROUND(AVG(f.Relative_Humidity),2) AS AvgHumidity,

    ROUND(AVG(f.Precipitation),2) AS AvgRain,

    ROUND(AVG(f.Wind_Speed),2) AS AvgWind,

    ROUND(AVG(f.Cloud_Cover),2) AS AvgCloud,

    ROUND(AVG(f.Sunshine_Duration),2) AS AvgSunshine

FROM Fact_Weather f

JOIN Dim_Date d

ON f.DateID=d.DateID

GROUP BY d.Season;

Go
--Insight 1: Best Time to Travel
SELECT TOP (10) *
FROM vw_BestTimeToTravel
ORDER BY AvgTemperature ASC, AvgRain ASC;
GO

--يعرض أفضل الأشهر ذات الحرارة المعتدلة والأمطار القليلة.

--Insight 2: Outdoor Feasibility
SELECT TOP (10) *
FROM vw_OutdoorFeasibility
ORDER BY OutdoorScore DESC;
GO

--يعرض أعلى Outdoor Score.

--Insight 3: Weather Comfort Score
SELECT *
FROM vw_WeatherComfortScore
ORDER BY ComfortScore DESC;
GO

--يوجد 6 مدن فقط، فلا حاجة لـ TOP.

--Insight 4: Coastal vs Inland
SELECT *
FROM vw_CoastalVsInland
ORDER BY AvgHumidity DESC;
GO

--يظهر الفرق بين المدن الساحلية والداخلية بوضوح.

--Insight 5: Rainfall Ranking
SELECT *
FROM vw_RainfallRanking
ORDER BY TotalRain DESC;
GO

--يعرض أكثر المدن تعرضًا للأمطار.

--Insight 6: Heat Index Analysis
SELECT TOP (10) *
FROM vw_HeatIndexAnalysis
ORDER BY HeatStress DESC;
GO

--يعرض أعلى Heat Stress.

--Insight 7: Monthly Heatwave Detection
SELECT TOP (10) *
FROM vw_MonthlyHeatwaveDetection
ORDER BY HeatwaveDays DESC;
GO

--يعرض أكثر الشهور التي شهدت موجات حارة.

--Insight 8: DTR
SELECT TOP (10) *
FROM vw_DTR
ORDER BY DTR DESC;
GO

--يعرض أكبر فرق بين حرارة النهار والليل.

--Insight 9: Thermal Volatility
SELECT TOP (10) *
FROM vw_ThermalVolatility
ORDER BY ThermalVolatility DESC;
GO

--يعرض أعلى تقلب حراري.

--Insight 10: Extreme Weather Ranking
SELECT *
FROM vw_ExtremeWeatherRanking
ORDER BY ExtremeScore DESC;
GO

--يعرض المدن الأكثر تعرضًا للظواهر الجوية القاسية.

--Insight 11: Sudden Temperature Change
SELECT TOP (10) *
FROM vw_SuddenTemperatureChange
ORDER BY TempChange DESC;
GO

--يعرض أكبر التغيرات المفاجئة في درجة الحرارة.

--Insight 12: Most Variable Months
SELECT *
FROM vw_MostVariableMonths
ORDER BY TemperatureVariation DESC;
GO

--يعرض الأشهر الأكثر تقلبًا.

--Insight 13: Most Stable Cities
SELECT *
FROM vw_MostStableCities
ORDER BY StabilityIndex ASC;
GO

--لأن أقل قيمة تعني مدينة أكثر استقرارًا.

--Insight 14: Humidity vs Temperature
SELECT *
FROM vw_HumidityVsTemperature
ORDER BY AvgHumidity DESC;
GO

--يعرض المدن الأكثر رطوبة.

--Insight 15: Seasonal Comparison
SELECT *
FROM vw_SeasonalComparison
ORDER BY AvgTemperature DESC;
GO

--يعرض الفصول من الأعلى حرارة إلى الأقل.

