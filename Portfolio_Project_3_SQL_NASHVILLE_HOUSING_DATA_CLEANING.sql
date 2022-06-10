-- DATA CLEANING

-- First of all, we show all the data contained in the table 
-- where we are going to perform Data Cleaning. 

SELECT *
FROM PortfolioProject..NashvilleHousing;

----------------------------------------------------------------------------------

-- Secondly, we note that column SaleDate's data type is datetime. 
-- This data type contains also hours, minutes, and seconds. 
-- This information is unnecessary since every row just repeats 00:00:00.
-- In this case, it is good practice to convert the column's data type 
-- so that the column reflects just the information that it should convey. 

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing;

ALTER TABLE NashvilleHousing 
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

-- Verifying that the change reflects our intentions.
SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM NashvilleHousing;

--------------------------------------------------------------------------------------

-- Thirdly, we try to populate Property Address data

-- 1. INITIAL SITUATION
SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is null;


SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID;

-- From the last SELECT statement we notice that ParcelIDs are sometimes duplicate.
-- When they are duplicate, also the PropertyAddress is duplicate. 
-- This means that every ParceID is associated with a different PropertyAddress, 
-- Therefore, duplicates of a ParcelID missing a PropertyAddress can be fixed 
-- by associating the same PropertyAdress. 

-- 2. ATTEMPTED CHANGES

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b 
     ON a.ParcelID = b.ParcelID
	 -- (rows with same parcel ID)
	 AND a.[UniqueID ] != b.[UniqueID ]
	 -- (but different rows, in other words, duplicates of ParcelID)
WHERE a.PropertyAddress is null

-- This SELECT statement performs a SELF-JOIN.
-- Here, we can see that NULL PropertyAddress can be replaced by 
-- the correct PropertyAddress.

-- To turn NULL values into the correct address, we will run another SELECT statement
-- including the SELF-JOIN and an ISNULL column

SELECT a.ParcelID, 
       a.PropertyAddress, 
	   b.ParcelID, 
	   b.PropertyAddress, 
	   ISNULL(a.PropertyAddress, b.PropertyAddress)
	   -- (if a.PropertyAddress is null, populate it with b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b 
     ON a.ParcelID = b.ParcelID
	 AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress is null

-- 3. CHANGES
-- Next, we run an UPDATE statement to replace NULL values 
-- with ISNULL(a.PropertyAddress, b.PropertyAddress)

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
     ON a.ParcelID = b.ParcelID
	 AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress is null

-- 4. FINAL CHECK 
SELECT *
FROM PortfolioProject..NashvilleHousing;

----------------------------------------------------------------------------------------------------

-- Fourthly, we divide the PropertyAddress into individual columns (Address, City)

-- 1. INITIAL SITUATION
-- First, we look at the PropertyAddress column.
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing;

-- 2. ATTEMPTED CHANGES
-- Second, we divide PropertyAddress data into substrings. 

SELECT 
      SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
	  SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing;

-- This SELECT statement returns the PropertyAddress split into street Address and City.

-- 3. COMMITIED CHANGES
-- Third, we create two new columns in the table.
-- First column: Address

ALTER TABLE NashvilleHousing 
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1);

-- Second column: City
ALTER TABLE NashvilleHousing 
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress));

-- 4. FINAL CHECK: 
SELECT *
FROM PortfolioProject..NashvilleHousing;

--------------------------------------------------------------------------------------------------------------

-- Fifthly, we divide the OwnerAddress into individual columns (Address, City, State)

-- 1. INITIAL SITUATION
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing;

-- 2. ATTEMPTED CHANGES
SELECT 
      PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS Address,
	  PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS City,
      PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS State
FROM PortfolioProject..NashvilleHousing;

-- 3. COMMITTED CHANGES
-- First column: OwnerSplitAddress
ALTER TABLE NashvilleHousing 
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3);

-- Second column: OwnerSplitCity
ALTER TABLE NashvilleHousing 
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2);

-- Third column: OwnerSplitState
ALTER TABLE NashvilleHousing 
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1);

-- 4. FINAL CHECK
SELECT *
FROM PortfolioProject..NashvilleHousing;

---------------------------------------------------------------------------

-- Sixthly, we want to change Y and N to Yes and No in "Sold as Vacant" field

-- 1. INITAL SITUATION
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- 2. ATTEMPTED CHANGES
SELECT SoldAsVacant, 
       CASE
           WHEN SoldAsVacant = 'Y' THEN 'Yes'
		   WHEN SoldAsVacant = 'N' THEN 'No'
		   ELSE SoldAsVacant
		   END
FROM PortfolioProject..NashvilleHousing;

-- 3. CHANGES

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
                       WHEN SoldAsVacant = 'Y' THEN 'Yes'
					   WHEN SoldAsVacant = 'N' THEN 'No'
					   ELSE SoldAsVacant
					   END

-- 4. FINAL CHECK
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;
-- This should return only 'Yes' and 'No' values in the SoldAsVacant column


---------------------------------------------------------------------------------------

-- REMOVING DUPLICATES
-- Seventhly, we aim at removing duplicates. 
-- Here, we consider a duplicate every row whose data resembles 
-- the first 5 columns' data (except the UniqueID) of another row. 
-- 1. 
SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY 
	                                  ParcelID,
									  PropertyAddress,
									  SalePrice,
									  SaleDate,
									  LegalReference
									  ORDER BY 
									          UniqueID
									  ) AS row_num
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID;
-- Here, rows are partitioned by ParcelID, PropertyAddress, SalePrice, SaleDate, 
-- and LegalReferenceappears and row_num counts the rows included in every partition
-- starting from 1. 
-- If row_num = 1, then there is just one row in that partition. 
-- In other words, that row has no duplicates. 
-- If row_num > 1, then the row is a duplicate of the one that was assigned a row_num of 1 in that partition. 

-- 2.
-- It is possible to extract from this statement only the rows that present a row_num value greater than one. 
-- These are the duplicates. 
-- To do so, we need to convert the previous SELECT statement into 
-- a CTE and then run another SELECT statement with a WHERE clause.

WITH RowNumCTE AS (
SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY 
	                                  ParcelID,
									  PropertyAddress,
									  SalePrice,
									  SaleDate,
									  LegalReference
									  ORDER BY 
									          UniqueID
									  ) AS row_num
FROM PortfolioProject..NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;
-- From these results, we know how many duplicates there are in the dataset
-- and which rows are duplicates. 

-- 3. CHANGES
-- To delete the duplicates, we need to replace the second SELECT with a DELETE.

WITH RowNumCTE AS (
SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY 
	                                  ParcelID,
									  PropertyAddress,
									  SalePrice,
									  SaleDate,
									  LegalReference
									  ORDER BY 
									          UniqueID
									  ) AS row_num
FROM PortfolioProject..NashvilleHousing
)

DELETE 
FROM RowNumCTE
WHERE row_num > 1;

-- 4. FINAL CHECK
-- To verify that all duplicates were removed, we run the first query again.

WITH RowNumCTE AS (
SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY 
	                                  ParcelID,
									  PropertyAddress,
									  SalePrice,
									  SaleDate,
									  LegalReference
									  ORDER BY 
									          UniqueID
									  ) AS row_num
FROM PortfolioProject..NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;
-- The query returns no rows, as expected.

-------------------------------------------------------------------------------

-- DROP UNUSED COLUMNS
-- Eigthly, since we were able to split the PropertyAddress and the OwnerAddress 
-- into more useable columns, we assume that the initial columns are no longer needed. 

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress,
            PropertyAddress
;

-- FINAL CHECK

SELECT *
FROM PortfolioProject..NashvilleHousing;
