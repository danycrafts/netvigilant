its a flutter and dart development project, dev environment is windows.

The getter 'appUsage' isn't defined for the type 'Permission'.
Try importing the library that defines 'appUsage', correcting the name to the name of an existing getter, or defining a getter or field named 'appUsage'.
The getter 'appUsage' isn't defined for the type 'Permission'.
Try importing the library that defines 'appUsage', correcting the name to the name of an existing getter, or defining a getter or field named 'appUsage'.
The method 'getAppUsageData' isn't defined for the type 'UsageTracker'.
Try correcting the name to the name of an existing method, or defining a method named 'getAppUsageData'.

on search screen below the search bar add a grid. each box in the grid will be filled by discovering all apps installed on the device. and some metadata about each app will be displayed in a modal window which can be opened by clicking the button in any of the grids cell, labelled by the app name to which the metadata belongs. all necessary userpermissions must be take for android. aim is to get network and device resource usage data for other apps on the same android device. the search bar allows search in the grid items. use skeleton loading for grid items and appropriate theme based on the light and dark toggle setting.

for login registration flow create new screens, and configure a permissions strategy so that logout and edit profile are only visible when user is logged in.

further more in the search screen implement real functionality not stubs or mocks. list all apps on device as items in the grid cells. each cell on click opens a modal window which displays all possible metadata visible about that app. on app startup user is asked for all necessary permissions. also another factor to include the map widget should recenter when the public ip latlong are fetched so that blue marker and green marker both are visible on the map.