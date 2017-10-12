# openDAMP

Operations of openDAMP (open Digital Advertising Measurement Platform):

1. Categorization of websites resources (Advertising, Analytics, Social, 3rd party content, Rest) by using external sources (for now I use Disconnect plugins blacklist I have 
also the one of Adblocker Plus and Ghostery) and a list of ours that I created after manual inspection.
2. Web Beacon detection by checking the pixel size of the fetched resources. (it replays each HTTP request - 
it's not always easy to detect if the req regards image (jsp case) and replay only GIFs or PNGs)
3. Categorization of Advertisers based on the products they provide (by using g2crowd.com list), separation 
of Data Management Platforms, DSPs, Ad platforms etc.
4. Calculation of statistics for each advertiser (number of requests, Total bytes delivered, number of users 
served, popularity in the dataset etc.) 
5. User Agent analysis to separate mobile Vs desktop related traffic and identification of device and OS (Android, Iphone, Windows phone).
6. Calculation of statistics: (i) based on the full trace (ii) based on the different Categories e.g. number of Requests, percentage of 
traffic, average Latency, Total Bytes downloaded, and (iii) based on the different file types retrieved (iv) based 
on the traffic of different users.
7. Extraction of user's IPs and calculation of her overall geographic movement (by using offline geoIP database of maxmind)
8. In case of RTB related traffic, it first filters out possible duplicates from browser retransmissions and by 
using a list of keywords it extracts bidder (i.e. DSP), bid price, charge price (separation of encrypted and unencrypted ones), 
publisher, time of day, geolocation of the user, Cookie Synchronizations up to that moment, ad slot size, carrier, ad exchange platform and (rarely) the associated SSP.
9. Estimation of each publishers type of content.
10. Estimation of the user's interests by extracting the publishers she has visited along with the type of 
content they distribute.
11. Cookie syncronization (CS) event detection by looking for (i) redirections (303 and 200 HTTP statuses) and (ii) cookie/users 
IDs passed from one host to another through the user's device.
12. Creation of CS graph by using as metrics (i) the number of CS transactions each cookie ID had participated and the number 
of cookie IDs loaded in each CS transaction (multiplier of privacy leakage) 
13. Creation of user timelines, creation of time windows of specific width, and calculation of statistics for the traffic of 
each time window.
14. Automated production of plots and distributions using the results of the above operations.
