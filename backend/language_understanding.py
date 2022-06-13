from wit import Wit

def get_intent(message):

    client = Wit("N7O2LP2TRAYCUUVHTBV25IMY4B4MHB2S")
    resp = client.get_message(message)
    try:
        return resp["outcomes"][0]["entities"]["intent"][0]["value"]
    except:
        return "Error"