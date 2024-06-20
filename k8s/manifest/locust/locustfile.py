import random
import socket
import time
import asyncio

from locust import TaskSet, between, task, HttpUser

headers = {"Content-Type": "application/json", "User-Agent": "UnityPlayer"}


class TestScenarioCase(TaskSet):
  user_id = ""

  def on_start(self):
    # registration
    registration_response = self.client.post("/registration", headers=headers,
                                             json={"name": "test-" + str(
                                               random.randint(0, 10000))})
    self.user_id = (registration_response.json()["user_profile"]["user_id"])
    print("registered user id: " + self.user_id)

    # login
    login_url = "/users/" + self.user_id + "/login"
    self.client.post(login_url, headers=headers,
                     json={"client_master_version": "2022061301"})

    # tutorial
    tutorial_url = "/users/" + self.user_id + "/quests/0/tutorial"
    tutorial_response = self.client.post(tutorial_url,
                                         headers=headers,
                                         json={
                                           "client_master_version": "2022061301"
                                         })
    if tutorial_response.json()["user_profile"]["tutorial_progress"] != 10:
      print("CHECK: tutorial progress is ",
            tutorial_response.json()["user_profile"]["tutorial_progress"])

  @task(7)
  def quest1(self):
    # Quest 1 Start
    quest1_start_url = "/users/" + self.user_id + "/quests/1/start"
    self.client.post(quest1_start_url, headers=headers,
                     json={"client_master_version": "2022061301"})

    # Quest 1 End
    quest1_end_url = "/users/" + self.user_id + "/quests/1/end"
    self.client.post(quest1_end_url,
                     headers=headers,
                     json={
                       "client_master_version": "2022061301",
                       "score": 100,
                       "clear_time": 20
                     })

    # Get Ranking for Quest 1
    ranking1_url = "/quests/1/ranking"
    self.client.get(ranking1_url, headers=headers)

  @task(1)
  def raidbattle(self):
    # Raidbattle Start
    raidbattle_url = "/users/" + self.user_id + "/quests/raidbattle"
    raidbattle_response = self.client.post(raidbattle_url, headers=headers)

    delimiter = ":::"
    semi_delimiter = ":"
    connection = raidbattle_response.json()["connection"]
    endpoint = connection.split(":")
    ipaddress = endpoint[0]
    port = endpoint[1]

    # Quest 2 Start
    quest2_start_url = "/users/" + self.user_id + "/quests/2/start"
    self.client.post(quest2_start_url, headers=headers,
                     json={"client_master_version": "2022061301"})

    buffer_size = 4096

    # Join to gameserver and start raid battle
    tcp_client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tcp_client.connect((ipaddress, int(port)))
    join_response = tcp_client.recv(buffer_size)
    print("[" + ipaddress + ":" + str(
      port) + "] " + "Received a response: {}".format(join_response))
    player = str(join_response).split(":::")
    player_name = player[0][2:]
    print("[{}:{},{}] Joined".format(ipaddress, str(port), player_name))
    tcp_client.send(b"battle:::start\n")

    boss_max_hp = 300
    while data := tcp_client.recv(buffer_size):
      if str(data).__contains__("start"):
        print("[{}:{},{}] started raidbattle".format(ipaddress, str(port),
                                                     player_name))
        data = b"boss:::300\n"

      if str(data).__contains__("end"):
        print("[{}:{},{}] end raidbattle".format(ipaddress, str(port),
                                                 player_name))
        tcp_client.close()
        break

      if str(data).__contains__("join"):
        continue

      print(
        "[{}:{},{}] player attack".format(ipaddress, str(port), player_name))
      damage = boss_max_hp - random.randint(1, 100)
      tcp_client.send(bytes(
        player_name + delimiter + str(damage) + "\n", encoding='utf8'))

      boss_hp = str(data).split(delimiter)
      if len(boss_hp) > 2:
        # When the response such like
        # player2:83:::boss:217\nplayer1:0:::boss:217\n, ignore
        continue

      if str(boss_hp[1]).__contains__(semi_delimiter):
        # split the response such like player1:98:::boss:202\n
        hp = boss_hp[1].split(semi_delimiter)
        boss_max_hp = int(hp[1][:-3])
      else:
        # split the response such like boss:::300\n
        boss_max_hp = int(boss_hp[1][:-3])

      print(
        "[{}:{},{}] boss hp: {}".format(ipaddress, str(port), player_name,
                                        str(boss_max_hp)))
      time.sleep(3)

    # Raidbattle End
    quest2_end_url = "/users/" + self.user_id + "/quests/2/end"
    self.client.post(quest2_end_url,
                     headers=headers,
                     json={
                       "client_master_version": "2022061301",
                       "score": 100,
                       "clear_time": 20
                     })

    # Get Ranking for Quest 2
    ranking2_url = "/quests/2/ranking"
    self.client.get(ranking2_url, headers=headers)

  @task(10)
  def shop_item_120(self):
    self.client.post("/shops/item_120", headers=headers,
                     json={
                       "client_master_version": "2022061301",
                       "user_id": self.user_id
                     }
                     )

  @task(10)
  def shop_item_240(self):
    self.client.post("/shops/item_240", headers=headers,
                     json={
                       "client_master_version": "2022061301",
                       "user_id": self.user_id
                     }
                     )

  @task(10)
  def shop_item_360(self):
    self.client.post("/shops/item_360", headers=headers,
                     json={
                       "client_master_version": "2022061301",
                       "user_id": self.user_id
                     }
                     )

  @task(7)
  def character(self):
    # Get Character List
    character_list_url = "/users/" + self.user_id + "/characters?client_master_version=2022061301"
    character_response = self.client.get(character_list_url, headers=headers)

    if character_response.json()["user_character"] is not None:
      # Sell Character, if the user has
      character_sell_url = "/users/" + self.user_id + "/characters/" + \
                           character_response.json()["user_character"][0][
                             "id"] + "?client_master_version=2022061301"
      self.client.delete(character_sell_url, headers=headers)

  @task(7)
  def gacha(self):
    # Use shop for get user_profile
    shop_response = self.client.post("/shops/item_120", headers=headers,
                                     json={
                                       "client_master_version": "2022061301",
                                       "user_id": self.user_id
                                     }
                                     )

    crystal = shop_response.json()["user_profile"]["crystal"]
    friend_coin = shop_response.json()["user_profile"]["friend_coin"]

    if crystal > 5:
      self.client.post("/gachas/1", headers=headers,
                       json={
                         "client_master_version": "2022061301",
                         "user_id": self.user_id
                       }
                       )

    if friend_coin > 5:
      self.client.post("/gachas/2", headers=headers,
                       json={
                         "client_master_version": "2022061301",
                         "user_id": self.user_id
                       }
                       )

  @task(5)
  def present(self):
    # Get Present List
    present_list_url = "/users/" + self.user_id + "/presents?client_master_version=2022061301"
    present_response = self.client.get(present_list_url, headers=headers)

    if present_response.json()["user_present"] is not None:
      # Get present, if the user has the present
      present_get_url = "/users/" + self.user_id + "/presents/" + \
                        present_response.json()["user_present"][0][
                          "present_id"] + "?client_master_version=2022061301"
    self.client.get(present_get_url, headers=headers)


class Run(HttpUser):
  tasks = {TestScenarioCase: 1}
  wait_time = between(0.5, 3)
