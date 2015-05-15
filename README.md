node-messagesender
================

Sends messages to Azure Queue

## Prerrequisitos

* [Git](http://git-scm.com/)
* [NodeJS](http://nodejs.org/)

### Quick start

```
npm install

npm start # Start application
```

### To Send Messages
**pricechange message**
```
GET http://localhost:4000/priceupdate/
```
**stockupdate message**
```
GET http://localhost:4000/stockupdate/
```

### To Read Messages
```
GET http://localhost:4000/
```
