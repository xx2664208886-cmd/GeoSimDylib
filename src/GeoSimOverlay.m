#import "GeoSimOverlay.h"
#import "GeoSimEngine.h"
#import "GeoSimViewController.h"

static NSString * const kDoubaoIconBase64 = @"iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAErlSURBVHhevb0HdFTXuTbM969v3f//kps47nSBhLo0XSOBEFW9i14NBmxjm4DtGBdwIXbsOO4lthPbuAEOYFyC6b0LdYmqLqq66Ooz8/zrefc+I5k45ZbvDmtzzpwZndn7effb371PHwBjAKz4n21uaW5gRSew4mq3e0Vda+eKqpb2FccbWlcUXWxdUVDXuSJPWveKvAa3tBzd8pogrcBoDarlNfEz94oc3eS98Tc8yr265d5Fdeq3Klpa5bevdnZLX9gnNqOfbjf7+uP+/9S1/2zro0/+R19uAK1uD5rau1F9uR3HG6+jqKEN+Q2dKGh0Ib/Bg/xGSMtt8CCv0YO8JnWe26TO85sgx7xmdc7v9r7+4+/x3CPflaY/y21yIY+/Wd+BYw2tqLrchoa2Ttxwe+CSnnp0+/svj8cj7T/7+h8lQDeAS51uVF/uwMmmVhTVt6OooQsFjW7kN3lUI5ACOIHXIBsg6ve5zUCOAAnkkwD63CCG99jkQW6jW5rcu0V/t0UToplEUH9b0OhBQX0Xihs6cLqpHeevdeFqt1v6/I9eNxPgP0qM/xYCePQ/Ob/p9/mWs6mloxuVl9pRWN+GnNoO5DZ0CUAKcNVkJnvBNmapmvU5mgAELIfXGwmuQQQPcpvdClhNAHXUBGgiAX4CeDnXnKF/J5+/2+BCfl0HSupvCIde7XIL1/6jV29C/EeI8F8ngP4tIYEHcLvd8Oju8v9LXS5UXm5HQW0rcuu6kNvowtFGD7KbPDhqgCkzVQHeIz7IEQZAuun3OY0e5FAckQi83mJ8RxOvN0cI6G7v5+Qe9Vv6bzUHGYQmsYz+5JNz6jpRUt+Ks1c6cL37H5PhPwK88fqvE+Cml8ELlPFnr3aisKEVR+s44/UMbgByGiHgH21UBBDQZUYrcA0wDLlO8ChCCpuBgl6z1xAnuQSZRwHYo8ST9/NeBNTXeA8SQLhKc10PATTxSYAmj4im/HoX8mvbcaK+FfU3OtHxI6A9iu29E/HHH/2z1387AboANLR140RDu4ianAY3jja4lQLVBDja4EE2r2kCyHUSRZoG6kcKVctp3QTYXt9R4oWcoIjgFTMikggoOaDnXImlHo5TIkkTneKKhgAJ3uRBsSh4N/IaXShsdKGovgPlza243NEtovVfwPgfvv7bCCCWjcsjMrPgYiuO1rsEaBEVnPXSFPA89sh0nmuu0Jwh4MgMNEDj0Y2CJjeKmhUwXmWrZ7TxvvdMFmIYSt0QPV5C9IAvM14faRDw/kXSgMJGEt0jvy33afSgsKELx+pbcf5qBzr/ixT4LxKAsCuJ39LhwsmGG8itbUdufa8Z37sJ0Fp2E5he8pcEMcQSP1MzW4FRyGOjCyXNHhxrdqGkxYXiFgLPme1WSpj3aOiWmcoZTMD493yvmrKEjKNhbfF3DM5SRHZpIrtRxNaoiEEiKM7gd2g1uVFc34GqlnZc66beu/nFK3979ebXf5EAyrSsu9GJ4tobyK3rRG6DG9n1LqUoNdAG4IoIevZppStm5E32OwnFwZ645EHlDeBsB3ChHTjH8+vAmevA2VbgXAdQ2QaUXHLj2GWgog2oaQOqrgNlLV0ov+xC5TV9rRUovQYUN3crAjVCzXABGgI6CVrY7EZxs6eHCM2a6+T7mhgyQZSSLqzvxMnGNjRpkdTz+r9KAHVjst+ZK53Iu9iKHILOWUwLp0GJH7YeDtCmJQEnWzcq9ubgKUI4wwqbXDh5BajpUCDnlV3A2o3b8bvX3saDDy/B9GmzMWHCVGSkT8TEyTPw68eexIdfrMfhkkrsyz+FN97/FAsefARZk6YjOSkNySnpmDJ9NhYuXopX3/sYOw4XoLTuOs61AdWtwMlLQHGTSwGuwVWgkwCKOD3vlehjn70cp7k5v8GF4ro21N7okglJM8RNs/Rm2H7i9R8ggHE7ihwP2t0eVLRw1rchu6EbRxvdIt+zhQBKznuBN+StlrVkYQ5QZl4TZ5wL1W1AfRdQVFmLD1auwvQZcxBhcSDcbxjsgQEYZQ5HfIQDKSOGIzU6GvGRERgeFgqTrx+GW2yIDDfL+SiLBYnDo5AWE43k6EiMc1gxIiwMtoAgOMPNSE1IxdKlz2H9X3fh9IUruNgBlF8FjjW5UMK+iLWlRI4Sf2yQa8Kp2krjZFNiUxFCxFltG85ebUfnP5n7vUnzLxNA/YliqxsuD8qa2pBX24acRjXzxYQkAXpbPTQ9jSadVAOQmd9MC6NbZiKB35tdgMWLH4PdZIHJbxiSoobj/gmZePyeWXhq7j34zczpWDx1Mh6akIX70lMxPyMZC9JTcH9GOuYmJ2NuUjLmp6ViVkIspoyNwaQxIzCZbXQ0po8fi1lxsZgRNx4TR43GOJsdztBwJMUm4ZVX30HBqTNo6AQqDUK0UFSpWU+uEOdMgFfWk4CvLSlOOGVs0MJzCxFqLnegQwD7e2LoP0EA40VLp6KxFQUXO5HPHxVXX1k6VL7SsUZt6dR7kFevCOElCJVgfTdOXwIau4EjhScxf979CBzkg6jgIMxPT8XyBfPx3H0L8MSs6ViYmYIZ48cga0QkUp0RSLJaEW8JQ6wlFHHWMCRYTcgYHoms6BFIsFnkerwt3NsSbGFItJuRZDMjxWZBWoQDE6NHYMLIERhrMiGMv2tx4NlnXsDJqlo0dAMnWzyi8MmdheKQKY+ak004Xc7dOtShCWCIJI6xtk2sQRLhH7tu/wIBRJZpeUbnqqypVbzaogaXgMvZLeDWuyWIJsBT/pMYBgF4TrFEh6ahC2fagNLzl7Bs2XMIGuSD4QGBeGjCRDx//wI8O/9ePDJ1Cu5NTMCkkcORGmFFosOEpAgzUiJsSImwIonXpFmkJdgtiLdbkOiwIdHBo2rJERYkOczSUiNsSHOw2aWl2K1Ii7AjPdKJMeHhCO7fH6MjhuPjlWtw/pobldeBwgYqbDXbZUwCtluIQEPBMHeVOKJPYziQLhTUaSLcxAM3x45+kgC9v0R5z39tlPnNrSioa1cOicRMtDjRjYpVWFWIojhBiSAI+GRrKsA132wW+R7Y927MTU4S0J+59148PCEDU8bEINlpR7LDilSHFWlOG1LYCKCXABZFBIcFCRFmRQyHasZ1RTT1vWRpNqQ4HEglAewkhCIAOSKF1yIjMTokGAH9BmDG9HtwpLgc59sgXjCtuuwGD44I+CSEW4dReghgEIOmrGEh5V9sw5krSif05oR/SoDeL3610w3UMJBW2yYsSRuYSkoUj8j0HnvZYNn8Bh1/0a786StAZUsnljz2NG772b9jjCkMj8+egWfmz8HiKRMwZdRIxFK0WMOR7CTYBMcmMzclwi4ApjrYrHIt2aFmNwnlnfEkgMPqPSYKcRQRhBAOEpaE4H0sSBEi2/V7mxJxEXaEDhiIMP8QfPLlBpxrhVg5R+pdQgCR+U1AtnjxhjVkeNYcL/0QI5bkQlFtGy5c75AIQW89apDkRwQwZn4PBygn68KVThReaEMBxYyIE5eIFCOGw+skAAlRKFyhTDc6S+SWqhtASVUDUlIy0ffff4HZiQlYPn8unrxnBmbHj0e8zYxxplDE2c0CJGc5AVFEsMs5QTLEB0VJqt0sIKbarUi2W5BkNyPZbhXRkkLi8FoExY9BKIokfkbiKS6S9yRmhA2JFGG6JUfYEeHvh3633oHnXngNZ69xHG4vAaSJAiZHKAyUL6NCGcbElDgSHci6NjS2dSvIb8JYCODxuKGajit5XNL4B03tXSi6eB25tV1K3huerOYAcc3FplccwNiJwQ3FTW6cbQeySyrgdEQhZOAgsWSev28els6cjkkxIzDeHIo4mxkJApRVA9CLAwR4G9KddqSLHLeKCEnnNa9c1zPYbnyfypacQkJaVCPYTtVEJPE80ookpxVJkUqfJDnZDxPi7eHyflR4CO76xS1Y/NhynLnmQfElJX4IvOIEJft7sHBpr13lF3gu4ZN6F07Vt0lYWxlHhl71oA/Ta94Zr0UTz6l8mRk6Wd+KvLou5MjMp42vtb4O6Xrdef6gmJbKhKODc6YdyD1ZBYfZjpGhwXhq7mw8P38Ofj0xA6lOO+KtJgFdmp69Yq0QzAgtGuwKSIKd7gVUE8XB61YvAQR0DTivpdh5VH9LovA+BJ7KmYRIchJ0KnItqvQ59UqCPVy4aowlHHf94lY89OsncPa6GyXNKr8guQbttct7bTHRj2DriSUpTiiq70J5UxvaDWVgcIBBgJ6QqvqAcr+6uQOFtd0y85V1wzCDG0fIelSyOrZDIqj4CL1HZeNT7Jw634gxMaMxxhSOZffMxrP3zMKDGakCDMUGZ7mSyVYkWy1iJpIIFCVUqF4CyKy3yudKifK9pVezIp3XRKZr0STiSX2muIPEUMCnOMxCrBTRD8pKEhFFi0mIoTghyW6S6+PtVvS/9XY89cyLqO8AjjW7vWNVPgJDGJr7JWzhQZEE9dTnVMgFDdQHHbh4tUtFUX9EALfBAepIItVf70bRhTbk97bjtYWj4jw6xqNtYcPjpRw8ccWDc1c6MDFzCiL9A/DU7Jl45p5ZeCA5CclmAmRDhjMCGQ6KFS3jbQTYLIRIttlEhos8p+1O0UKZbzNr8Hs1EkeLJQGb37OTAD06ggQWvSKgKx0hHCGKWBGAukLMVm260opKpl7hb0baEeewYejd/fDhR1+iwcUQhkccNsNZM2a8YYjQKlRRW90alH48VteBS+0ur2mqlHAvs4hnzPxQZhXWuzT4OiFuyH9xwHpFNrXdT66gHDzfDix59En4390Xv5k+DctmzcD8xHgkWMIF0HQC73QI+CLD5ahmtihVEkIDJxwgNruS+4Z44QxOc5iVCBIRxfdK5Cixo0SOWE0CNN8ry4czn+8JPoklSts7+3muuCHFrlqa04r0EREYbzEjZIgfNu84hAudJIIbxS3KY6bBUczwijeOpIOMksnTEoKNoqiZokgZOT/SAWxdHqCmpQ0FtZz9SqOLnPM6JNrL/VG0U8X6aapVtgKfrvkGfW+5BQvSUrFsziwsSIpHrCkc8RYTEi0mATPNaZdmyHcDOMO8FLFAS0XPZCW2esSFMYMNTlAzXjX5TFtJSiEb31cK2CCK4hANtICuOIBmMInFfk2Ickp/M6KcmDByOKKDghBtj0JJ1UWJ1KqQhdZ7LR45yszXolkwo5TgBNbh8MK6dly83imS5sc6gDncdhdKLraK7Z6nCaDMTaVojFlPt7x3/pWKmVZCQcVFhASEICHCgWfm3oP7U5MF/HHhoUi32zF9VIwMLo0cQMuGhBCrx5iVygwV54sOmVOZjZypyqRUBJLvUFGLSCHYN+uAXiB7CaaJKr6FaoYYSnX2spzE8bNg8ogoPD5lMmaPGyscmzU8UkIY9BPmzFmAi63AcQ26V/zoMLaIZENEG06azn2w9OZEw3Vcc7nRh0VIRlUDw8sVEmTr6JHrImKYpuuhqpEsMbw+FRNxS4jhvoWLMfSOO7B09kwsnpSJOGs4RocFIclqxpJJE/BQZhoSLJSvWtTYTAoEW484EaUpnistJM58pQuSbCYk2JRiVN6tltkRve18ZU0pZ0wTjJxjNyGRsl3CF9p7NuQ9LR6HSYkoOm12kyhrcsfirAwsnzsLU0dHI8NpQ9bwCKQOj4TPHXdj5aoNqO1WEV2J7koUVSWIjLSozH4jRarPJcVa145z1zoNP0Ap3obWLhRcvKEDTyr6JyxEB0y8X1XeISk6I3UnFoELFa3AD7uz0f/WOzErMRGPz5wqs3tUaBDGm0LwQGoSlt8zUwYynk6XOVR0QGZkhJieE6IihQBKlpMQWjbbTEKcFKsSCelOKxJtBE03A1QB2vCEbXKkb8Em8SKHBfHyXSsSIkyKCE4r4u0mTIiOxIQRTiTaTEiPtGN23Fj5/SRrGGaOG4Xn5s/FkslZyIxyIGO4A5nRkRgeFIDoiBES0zp9Wc18r8LtlbNWhooqLFAGiyIAMT7W0NbjCTNyV9rUitz6LnE2BHgJNSu5LyEH/og4GSpurpoLJ5pduNjmxoSMSXAOC8ATs2dh2pgYjA4NxujQEEwdFYNlM2dgcVYm4i3hGGMKltDAY9OmCXtnRUZiycQspNqoHxQRDJtfKVYLUiwmPJSajPuSExBvChOwaaomOJQTJ8E4XuNsl5ltxIcM217FjdiSIpXNz8aI6azx4/DEzJnKALCGY+mMqXg4PRXJFpMQ/LFpU/DsvXMxezwJY0V6lANpIyIx5Pa78NLv38KFDi0RjJneKwdCItBiVDlvZT0a32HJi+IA5nTbXaJ4pYrBCDgx5KCtHMOelTRcozLDaA8fb+nGxU7g+y174N9vABZNnoQHM9Nklo8TxWvGogmZQoAZo2IwOiRQPnsoMwPL58xGekQE7ktOxf0pyUgwhYo+yHTakSF6wYokc5gAk+W04+kZ0/BQegpiw4MxddxoPJCZhlhLuHjSArTdjAThDkO0WMTZi7WakMCZr4N3JIA4ZE4ezciItAnA9ycnIjE8BPclxOO38+ZhgtOJZKsJ0ziB7pmDh7MyRUekRdmQGmXH8OAgOMLtKKxskJSoIV6Uk2rMdFX5ka2Dd0YSh/gyTCEEoOVT0dwucXp+qOIdKuzKo5eNdIaICqdYwHej9LIbDW1uTMqajPEWi3i7mcNpsjGwZkJW9HA8NWsGHkpPRWxYKGKCAzBlVAyemzcfC5ISEWcKw5zEBKQ7nUg0mwTsjAi7yNtkSzhG+fqIszU1ejienTMTD6UnIzY8CPcmxGHprJkSwIt3mDAzOVa4wCv3JcZjwdiwEEQMHYIkhx2JEXYJPSRrDkiJsiIliqLOhEcmZmL57JnIpOUTacfcuPEiIsVJtFswbXQMZowdLcpZKXIrEiMdGHzbXXjtrY8k78ykDPGTggOC38yYkQLf8JpZs3S0V+2SEIAxiuK6dgE6mx/q5ALBF69XiyTehCyl6mU8ONaibP4tu49IQmXJtCm4Py0J8ZZQFRa2mcVymJsQjySbRZTxyOBAzE6Iw4OZWUiwmIUb2GLNoUi0mkQpU/xkRtkxLtgfo/yHiuyfNSYGz987G/enxGN8WCAWJCXgydmzEWcLx3hrmJLnWt57QwuRVowKDYBlQF/l2EXakBxJAuiQhI4H0dSdMToGS6dPw8QRw6UPlP9CSHIJAaepSgNA5yCoe0hMq99QxI6Oxem6VsltS1kNOUDOdeRU8NQc0ezB0WaVRRQC0Ao6f7UTefWdmj16iqUY/TvSyDAsk+zK0ZI/FCKohHZtB7Bw4WJEh4TiaZn9DiSIXa3iNbTfE8xhiDWHYZw5FGOpgCk2zGEYz+vkFH2Ms1C2M3liRUakHcP9BmNMSKBYRbPGjsKK+XMwc0wM4k2hyIp2YkbsOIy3kgBKzFChSn6AooZhBKcFIwOHIuS2XyDeHILUKJsOwFm8RKC1Q0eLMzszKkKsL8MRU6FsHbbWnjitLbm/OG4mxDlMGNq3H9Z8ux2lN2iOK+DVJFbgc1IbhDACeTynyOrT6caK082tyG3ollmv6jY1pYyQq84GMd9LjjiiZVjJZSCv/CKsoSbMT0/HwxPSkWQLV2yuzUgxMQ0PlFYK5bKkCtkY9FJyO8EaLlxCxUlgqGRtg/oJd9BenzgiUmZ/mg4PxFvDMI7Es4cjTiwcgsLgngpFS7ghworxgX7IsIYiPtRfLBiJhorsV0QQc1NfM0IQ6qidPgkSqrgSG98nSeZNGQBJThv8+/XHvQt+jeobyiE1ZL2a0G5ka87gxFbEcYsIEgK0tHevKKpr1bWSPUVSXrtVU1IioY0eHG4wmgvlbcAfP1mNoAED8eTcOWJiShzeaZOZo8BXyRAOUmx7fiYKsifWwr+hnDXCD5yRFD/mu24XThG5azMh0RqmxIPDLCHj+Agz4hzhXuuGoKkAngpXZDojMHroYLz7yAOY4jSJx5saadcZNoYmlL8hzpp43TofIASk7Of91FHCIb19DKdNTR67CSOCg2ANs+Lo6Vocv9JTLi8EMMxPkfnEtaeYjJZTn/PXO1cU1HeKi6xK9npi/UachyFoafXA4QY2VfvDvOmMmfMwxmzFo1Onij1P5UfQJcopsX0FPMPLxoCVg8XBqTCADNDIZklyxYT4kAAkBgdgfHiQ11liiFhxTrgigIBPm15nxCSAZ8xWK7KinIge3A8bfv8MXr9/Okb7DUZGlENn2ZTsJ+jqbyjj2Z+e2a7OOQ72UYklb7ZNi6FEB/tixpC7++LPX66XUIxIkl5cIM6YcSTwJIB2YvtUtLSvoDlkOAvGzDfCDMp5MMLRKuRwhHlefl7VCIc5AnOSU0TRxoWHIslmRarNhlSGlmV2M/TLiKcKqPHIWSRxGSGCYnHxVDnQCCtGBw3DvHExWJgwFiP9fYWDBHyZ+Zz1lPXa+fKKCgWYkYxhozU2fHA/fPjoApR98zFGD7wD6dIfNQl6uJBOF7lMVU9Ido0K16a4UsWglOJVfoUBvgpZs39BAwfgvoVLUNOqrEWZ+YbXa4RsjPpTbU3Sse1zsqF9BSOYhnziH7Gm3sj699RRKsqqamcPTl4D1v6wG8GDfbFo6hSkRUVIWjHBakaSxSxOjJpRin17O1WGXhA57DXrCKYKAdj73Ya3F92LJyelwukz0OvF0sxkBUSPh6tnsE3/hiRtjOyZHVlRERjpOxhLM2OBk/vxePoYDB94N9KdTEEqgtP7ZZhEEcBoSjQqnaXyA0IAowrDsLQkX6DiUvSMR0WNQsnZS6Ib1cod5RUrz5grdDwoYNMFxUIALlbLbez2OhBG0KiniErFsVV+06h6cEsl2/MvvgrHMH88PHGCqtVhnQ5nkNWMFIsBTK+wrlgS4YoAWvkZiREV9TQjwRyC4X1vwbE17+OleybA3u9O7emaEU+wZDYqEUBQjKgnlS5BHxcUiNjQYJH/WZFOjA30x7QoC9pztuDY6ncxfMCtiGVsijOXxLSFK7AFdPZZxZ1EfIolpAmgdYzRqPB5FD0hfTMjeLAfNu8+KlFSqa5r8aCQ4eoWJe8pelhC780fN3vQR1YjavnPi4bIMdxoif0Y5SfaByBRzlwDpk2ehYSICNyTGC/WipiBMqvCkUSbnoRgLIfihkE3OkZBfkiyhCEtUslhiYzqJAlnprPfHViSOByu/C346NF5sN55qyg6iiDOOMaGRESI7NYcJnU/igCjhvkhalB/AT8z0on48DCMHDoQVRtXAQVb8fYD0xF2689F1LCfJIC6JwHVkVJdEkPQRcFT5BFwIYSyttS5ESw0i2JnSctb73yE2i5VMFzCAi9GSxklZsxMx4uUKFJxNSGAyHhDURjpR62AxauTwBuriFW1GCvHjtc0ISZiBGbEx2Mik+v0SDkTNBHICQY7CxtzFltNIlIYb0mP7Mnhisx22iUUMWbwXchZ+Qd05W3Envdfgu3OX4mJKmahl1MIkgoj00umfc77MGQ8Nsgfplt/gRRzmEQuaQ2F/PLn2P7+H4Ci7bi0ax1mRZnguPsOFeKWCCs5l7+hY0TCXarIS2S9FH+RED3RVMljSw2SngyRdph8fPDg/YslbXmcBLgEIYBRKk9uMAJ1hsHTh2txpYqtl9Uj2a16RQiDI6ioJQ3XrErGN+3JhsU/GA9mZYlSo9fLWcVwsbLvlYJLtFkQR6vGYUFMSDDM/fspxczaHzH/VJIkPdIBx9234Y+L7kHL3nW4dvhb1O3ZgPgAH3HGWKzFCKqK7/dOwPdKyDjtiBk2FFMjzYgdNhgZEVbhBMvtt2LZzAnAmUJ05m5C6dd/RoLfAIwcMkiIkGgJV36IBPTIZb3qjXrJ/N6coLhSOX5i6UU6EB0SjOTYZFQ3tUsdVEmLyhVT9CgOUCJITFLt0PaRRdC9yseVxcNEjHFN6QJqbiP6yejf2+99gsigEPx68iSvxWOYcYoYJIAKEYvlYjcj0t8X5v59xdaWhIhkqCwSXRzhMwD3jrKhbuda1O/7Gh2nDsB1ah+enpIEa787kB7lRIzfECQxjO106JSkUugqi2ZBqtOBiAF34+X50/HbGVlw3HkrJkZFYnyQP8b5D8Glwn1wlx+Gq3ArCr54G+N9+iJm6GDlYBk6gH3WIRFymwG68jW0AdCLqxkCYdKIHBBrM8NpsiL/RI2qhWpxifwvktyxsQhEOblGllEI4C0l1Ml3VdfZ855NlSEy2dyN2nbggfsWIcERgfvTUpBCkWIoRG3WiSITOcsB0Ps1wT6wL8z97tTermJxxmfGBPghIdAHJV//CTeKdsBdUwDUnoDr9D4cXvk6HHf/SoAZ7TcEI30GYmJUhDcHLPEZOmk6URM1qB+WpIxD4+5vMdMRAvtdt4qYst5xC759+yWguRzu0v3Aqb3I++wtxA0lEQYJQZXlY0FcWAiifYcIZyigycEK8CRde0TxpwhPY0I5d3TOWE7//dZ9sniEAUumKUX2S36gp5ZKwtWNmgMoaoy1VFL1IJXNKvcrrEJuEEKo+s6yuhsYFzMOU8eNxezYsUi2hXvzsFSK7LRSkCobRTYeFx6ChJBAiW4yLyyOGhM2/kMR5z8IRV+vBOpPAlfOADfqgOvngTO5uHF0I56bngrz7bcgPtgfcb6DMN7fB1mRTGcqrzdFxAatGZNYPWmhw3D1yFac/eFLPBwXieiBd8D///3fmB8bDbRUAZcrgIvF0s5sWYMJlkA4+9+t+k+/xGbBcJ+BcA4cgDhTiNdHEedR+zCS9NdesdStkghRDoQO8sEHH36Oui5FAIJv+ABeAhic0KA5wLtQWh8NIsjM75WWZI745GVgX+4phA4ZhntTUzFxRJTMeOU9qk5SjjLEq5LgKsk9YuggLJ2YjpSwICSawsUzHuXvh+TQAGx+9xXkrPsUq154Cu8uXYQ/PfM4vnvvVRzbuAo3cjahdvtXuG+sEwH/9v/gw0cW4IFxTtjv/CXGB/giKTwYSeYQxIcHIzbYH8MHDUTAv/0vZH/5PnCmAPW71mPrG8/h3V/fh2enZ2HTu6/gmzdfwKoVj+Gr55bg0Mq3cOSz9/FgwlhEDxmIBEsYMpwOjAnyw/DBAzDCd7A3vSkFXdryUaazUfhLa86BtEgnTIN98MRvnkFdu0pVeh1aw8TXkVI1sYUAEAKw1p/NW27eiwCGcs6t96D8GvDZ6u/gf1d/PJQ1QcpJDNmZLIqX4iBclYFo+ZxoD8M4/0FY98LTohxH+PrA1u9ORA68GxMdZkyyhyElxBdzYuxYlDwGCxNGIdMahNE+d2LPR68AZQdRu/MveOO+KSj84g1cPfQ9PnzkXtwzwoLkYB8kBA5CSqgvJttD8EBcNJ6fnYUT330GnC9G57Hd6C7ehT0fvorpUTZMjrTj3vHRmD9+BKbYQjB20N1ICxyC+aNHICHQF467b0eM72DEm0IwNmgYhg8ZiNiwEEnUG2EUr/MojiTFqS4ejrAj0n8YJmZMQfUll6xrFuy8FiWjybqmVqculQ7gzCf4xnou76oWvZjO4Ip6tyQeli3/HUwDBmNhZqYSJww/2K0YH+KP2PBAbzCLdTy0kEYHDsUDcSNQ/NWf4Lz9/2DaCCteWXiPgP3Kgqk48OkbuJy3HajKAc4XAeeK0Fl6BGf3fouWvG0AFeexXcDJPejI34zO/M1wH9+FK0d/QM221Sjb+BnObF+D5sMb0XViH1CTD095NjwV2XJPT9lhnNn1Nc7s+R5dZTnAGf5GMdqP7ce53V+jYM0HWPXsI3hr4T3462vPY06MDeZbfy6m6ijfwRgXNEzywcpf0cUANhNiQ4P0ezZWaDgwKjQUkZYo5JXWSa2QSBKNoQG8six1QoZbuRgEUCvTldzv2cNBUS+7jkVaLlRe8WBCxjSMCjXh3tQUifHTyqESGh3kh7Fh/mpm6PI/Br9GDO6Ljx+dj2sHvsPu915A88GNuJGzFZUbP8X1vK1A9VFpnopDcJcdhKf8IFBxGKjOBSqzxXJBxRF4+FnZIWndp/bBdWqPXONnqDZajiJkFe9HIhwF2M7kA2cLgEpePyINVWzqu6jIRlfJHnQW7RTz90+PLkBa8FBE330rxgwdJBk64QKnQywersyJoQhl/oAGhYgmO8aZLQgeGoit+wpw4orKAzNHwFCPbBZi7FehRZOXAIYZKtFQQ155w9GqIJfORPHZS4iwRSJjVAymjB2NseYwicezE6NDAzAmLFBlnqiknCxBtGGc3wAc/fg1dOVuQvexHegs2YmuE3uBqmzgTB7A2Vp+GO7yQ/CUK6BdpQfgLjsgxHALYNnwVB6Bm2ARxEoe9Qwn2FX8PFs+5/c8ci8S9DDcpYfhKeN9j6j35UfgrjwMT9UR+Rv+rRC7OhfdpYfRdXIfuo7txrmta7D9jeeREuCDRBMTOg5Vp+S0yTqG4cOG6vIWlW+mrxNnt2NY/8FYufo7lF2D5FAOa/y84sjAlqEI6gCDAOpDRR2RUb2oxc+ogPcXnEb4sEDMSU5C2nAnxlkYFqajYsOYsGBEB/qpgiexDGwSdsiyBMms4kz21OQAZ/OAMznwcLbW5AF1x4GG08DFY8CFEvW+/phwhbv8gHCGp+KwzFp3VTbcAtpRL/hucpCcs2UDQoAjwkUUP0IMAl92WHFB4ymg/gRQewxoOAk0ngTOFcBdnQtPdb70ifdyndyH9tzNeDRhJEb69JeSFUk2Oa0y0Zy+A1Wk1kFfR/sIEXYE9B+IF373pqxRZjEzs189SXotkrR11CenAStUoa1uveLXxiYZdKVZisIVjRt+2AOzbwAeyMiSyjSGHsQ+jqCnGo4oXx+9WEJZP2OCh2HuqAh0UjafyYenJhfu6hxpqD8O1J1Czner8IfF92HRxBQ8nJmM5+bPxA8fvorW09lCFA+JUE7RdEjAJREUAQwuYKM40eckkHCVElfq77LFtzh7cBM+/90yPDl7Mh7KSsJT90zB+jd/h+unjoiPQAK4q9hHxREUaR89Oh/2O34p1RNSTR1hxkh/H0QO1QSwKyLwyIkYOtgHC+YvQvW1ntX4vWuFDPFDr1hEkGwRIHapjl978wAqhsHiK67lZUHqO+9/hoiAENyXlq6cLa9loNKNUb6DMd4crMxRpwXOoQOwKHmUAuuMBp6zvrkMFwv2YX5qHO7+331gGTgQYXf3ReAtt8P/l7/CsF/8u/gWed+vlpnqKd8PVCjdICKm6jBQeRjg0TivJBGUzBeRVkYRdEDpl5pCfLj8UUT6DMCQn/8Mvr+8Bb6//BWCb78Twbfdhqgh/bF15TtAY7kYApwoIubOFWLH+y/DdtsvVHUeQxH2MDgG9hVnTUIWduoAm6pNirDCMWwYUhIzUVrfIQFMww8QAhj+gA7I9clucK8w1j0ZcR9vWYXO2pAAJS3dqOsEnnz6txhttmJecpLY/kZtJ52iFKcFI/x9JKFilA3a+9+JpyYnAmfzlUipyUXX+WMo2fEtInwGwueWX+Gz9z/Ao/PvQ8DtdyFiiC+ihgUg0i8A/rfeDsfg/ji14xvgQhHAmSxEOAhUsnFmG+dU1Pyc+oJyXnEMxZbrbBGenT8DgbcS9FsQ1rc/oob5I2KoH5x+/vj90iewZPZs3P6/+uDjF5ah/dxxtJdSPyjRVrLhE0T2u10iq/R8x4UHIeyu2zE6yF/HjBQBDH0wMjREquaKymtxgnlzLfMV6EYkVKUnFQcYplKv8jkjP2wkEUqaXTjfCsyb+wDSo2MwNyFOwgFZUQ4x0TLpmTrMGOfvg+ED+npj9Na+t+P5WRkKwOocdFbm4vGZEzHsl79EyKDBqKmoxOcfrYTvXf0wOTEJdl8/RPgOQ5R/IBy+vpgSG4t3li9FV02hmv0ijg70EEJA5/GAIoQoX36P7QhQdwKb/vwGJo4aiZToaExPScPs9ExYfHzg9AuAqf8g2Pz8UHXsOFa+/R58fvYz3J+ejPJd3yl9UXYIlVtWI2bwXRgXEijcTtETeMvPMC7IV3nhFEs6FEGxO95mgT04DIfyT6HimhEDUgQw6mqN3Vn6cHdBZfsb3lpPIVaPImZMw4XKS53ISMnEtNhYzBw/GumRTPvZkTXcgSy7CbOc4XhuQjymWYKREBKACcOdsPW9HS/OmaxkeXUOXBdP4eVFD+KWPn2we9MmdLS1YdAdd+P79RukOntiQgJC+/VHlH8AbEOGIHP0aOTt2IL2qgKgmmYlAdegi2xno1jqdS4KW/kBnvPHUJF3EK8/+wzGOyPlNzputCIqLBymQYMR4ReA/r/4BZ5+5DH57J6MLIwOGIb20zSBj4gPcnbnWowd2hexIYFi/wf+8t9w7xgHHhgbgbRQP6TR64+0eVtSZARMfv6yjoB606sDjCWsvURSH7XNo571Og9AkWRwgqQoWX59yY0TF68gbtR43JOUiKmjhiODBIiyIzPCjJnOUHyy5F5cyt6MnFV/xMhBd0l5d9Tgfnh2ZpaS4zQ5GyrwQHoKUkbGyIA3ffsdbv+3n+Gjd99FYW4exkVEwDzIB05/f0T6+8M8eDBOHDkAXD4LN212LWIEHB5FJ6j3Qhw5p0lK6ygHrppioLsVTz34EEL6D8S2v/6Ab9Z+DdMQP1gHDxWOC7i7HxJHjQZcLmTv3I1hP/8Z8r/5QjmF1Tmo3rkOo4b0FYvO0vd2THSG4kbJHjTs+RovTk5EVvgwCX3TSmKiKW14BMKH+GLVX76XdXICeAsxVRtBUaqoia3NUEUA1vooZSyVXJoAohu4+IDlFhW1iIkYjnmpyZgyMhKZTisyI23Isgbj9zPS0Jq7Xdx/XDiG3983A9E+AxAb6IfHJyYp85IeblUxRgX6idzn673X3sTQX92FkP6DEDZ4MMw+Q+H0DxDZzELfkH79sH/TRuDKBbioGGl2yow3QNczvkrZ9oog9AVy4KrKRffZY8D1S1g4bTr8br0NAX37IbD/QJh8hsA+dBhsQ30R2n8gRpgsuNzQBFdbB0YM88enzz8BNJSKGDq9eZUQYHSAL0Jv+znyv/kYuFgAVB3E+S2fY9FYB9ItIarAK9IiBWDhPkPw7vuf4lynFj86DyCi3eAASciQA4zqXV08pHLDyiLK0QVaJVeBIyeqMdxkx/zUZEwYzgUWNmREmCWmsuON54DSI2jaswENe77B5UObcP/YSFh+9X+wJCNOzaaafLjOHMODE9JxdN9eIcCbL7+KIbfcBfPgIZJRsvsOg91vGCL8hsHh54eQfgNwdOd24NJZuGmf04QVp0t7smIRaWdKTNCj8Ig9z5aHboYdWi9h4YxZCLjtTlgGDoZ58FBYh/jCOtRXCBHUtz+iLTY01TdKn9546kns/fwDCVcwoFf8zScYMeAOBP37v+HT5YuBssOo3/4FLu9fBxzfic+WzEF6mK8EICVg57QhdNBgvPDS67LXkVSa63pQKVPRJqikJJUIUgQQwMUH0LUtRkasCSi5AuzOPw17iAX30gnTSjbVasLsSAuKP38HXXnbcebbP+PoO8+h5KPf4/SaD5Ae7INJjhC4qvOAagJYgNrcvbh0vkoGu3rl5/C9vS+cAYEiky1DhsLqMwTWwT6w+vggIiAAF08WAXVlyjSkHqjOgaeGQNODVZaKhB7E3MztafRs+dmNRqx4fClC7uqLEf5BCO8/AOEDBiFswEBE+Qcj6O7+SIwZh47WdsDViY5zZfBUMp50RIyH7DXvI+j/64M3HpiFtv3fo+jtZ3D0taVo2PYZugu2YPcbyzDB5CdheSmTibAgdMAAPPHUc7L3EfWqVJwYkdHeOiCnoVsIQLlvFA5R9Egdo9ci8uDYVWD7kROwBIZjTkKClJ1IMtsShtlOC46teg84fRCewu24sOFPOPnnl3Hyo1eQ//GrWDEzFW2nD8FzphBuxmVq8tDVUCkEqDxdjtDBQxFvj8B4kwVRfv7IHBGN+zOzEG+1YnZaGtxXauGuzlfA0xPmjOe5NIqlHJHV6n2eBj9H6QGC2FyFbV+vhXXwYEwbPRZJFivGBAdjbEgYls1fiAjfQDx6/8PSH0/rZXSdKVaeNX2WhhM49MXbeHP+ZDRvWoWi159C0R8eR8vGlTL7uwq3YN87z2GyOQBJVhZpqYXeIQP6YdGjT6KiXZfzGMu7vI6uWm/cJ4dJeZFPPWaoHA15pbmCtS7bDpbAHBCKmXFxiOcGSkyWW8IwxRaKQ396RWZ4+9FNOLv2A3Tt/Q4n/vQyct9chiMfvqAAqsqBmyKi/Ahay3Pguq5Y/tnHn4LvrbfJXj4zY+OwMCMTc+ITMCLADwf++jU8jRVwUflKzKfXLCdXESgJxtHB09dEV+QAlTkSZ+quzEFbbSXmTczCqMBAzI2Nxfz4BMxLSEKy3YmQ/oNRlFMAeFzorK9CN+9FwtJhrD2Omq2rkf/2szj22hMof/95XPvrn9G8aSVcRVuB03ux8aXfYII5AAksy2FhgsOE4AH98dCSJ1DGsnUtRXo7uco3cKukvJJNekmN3haYXzZWdFA5UwnvOHoCloBwzE5MlBRjnF1VE2SYA7Fm+SJRWO35O3F2w8fw5GxD48YvkPv6U1j/xL1oK94hMlq809JD6Co9hNbKXLhvNKH9xg38ev58WH19ERMcgnHhYcgYOQJb1nwGNFWi87SKBynPVwXOOPNJ8O4T+9CRtxWu43uBGoomHUIwwhR0xBiOOH8cF08UYsGkCYgO8EfkkCFw+AyWHbgObNsMeDrhaqhCp4QhNDFJgPqTOP7VH7HpsXtw8fPfo33nl2jbswZV696B59Ru4PQefPDQdKSbAhBvC0Oc4GJCUP8BWPTI05oAalG7d+/SXiU/ffIutq9Qy5GUL6CKSvXKDmN1B5Pyl4C9RRVwhNkxLyVNPGCpLnOYkWEPw7KJ8bheuAuozkf9jnW4vHsDru/7Fk0/fI6vn5qH89u/EKXJKKfr9EG4Tx9A9/E9aCvZg+6zJ4BrjTh5ZC+2rF6Jnes+R9PpAqC+XAjlLqXjRdtfhRwMLugqPYyGvd+g++gWdOZsUTKbwT6JE6mgnISqyQX0bM+UoOtiOQr3bMa2tZ8jZ/tGuBrPANcvwlWZi+6T+wCGPKoOwVN9RBGi9hj2vP0Mij94Hq6jG9CRvQEtu79Ew64vgDPZqN/1FzyeMByp5iCZ/SRArM2EoAH98cSyFbKpIOtoZaubXoXPRuS5T1FDuypLEW+4V1COdaC6yFSW05ArKpswyjkK85LTMWVktKQgmQvNcFgwK8qMnX98CWgsRffpQ7ieuw2uYxzQEWx+aQnyP38FqDkKd+lBeE7uR+vhjbi6ax2u7/wKl3d8hcsHvoOL0UrmhS8eF4unm/EcbVp6wadzJQo3B91lR1D67Upc2/stOnO3SsSTzhqqNadIyFrnA8qzJSzdVc4A33GgqQq4eAqdxXtwfe96XN/xJa7tXIXWA2vhPrYFKN8nhKCSX7/8fjTuXAVU7ANK96D7xHa4T++W2NbaZx7CNFsQkrlIxFgYyFrRAf3w0h/eFAJ419x5RY8O+5AAJ5taV8iOh3r1u8x8XRFhVPmKR9zsQWlzF9KTJmDG+ATMiR0vlhBXOXJN12SHCY8mxaB653oJ9zIR4io9JKx89JOXseUPjwE12fBQ9GRvwuUtq9G6/St07PgLOnf+BW071uDqjtVoz9vkNS0ltq+jnpLd0rEZL7CV2eg8vhedRbvgPrlfR0Z1VJQKmPrG0AW6CQGZDzh1CDcObsS1bV+hbetqdG5fjc4da9C2/Qu07vsK7uPbBfCruX/F6sdno5PyvmI/XGX7VSiktgh5X76FBSNM4gNIMFLv9sKQRPDAAfhw5WqU62ppFYrQBW+98i59aq62r8ir7fSuAZAwhJGO1AEjqXFs9sjWMw/cvwSpUdF4MCNDLyViHMiBLIcVU6yheCprPMo2M4J5XMviXJzZ8hnWLpsHd9l+ce2Z023Z/AXaCf6udejatRadu/6C69vXoC3nB23XE2BlydC8VID3ZLtkVlO8GIkZ73f1d7xJGyp/KmXVFyFIVQ66Tx7A5d1fo23nOnTsWKvarnVo3/UXmQjdxVuAmkMo+/YDrF82H6jWgb+zucDFQhSufR+LY52YYA72rlkw1qYlOGwI9RmCb7bsw2luv6knsTfYqXPvUpbS1N69glsNc183Y6thoxmxIFZ2sazuYjfw8mvvY2SYBYsnT5aZzyAcs14slsqwm5ERHoj7Rzvx9e+eRO3ub4BTB9GVvxWrfnMPrub8ILOT2bDrB79TImjXWtzgoHk8/FcVvzdAlllrxPw16AK2Bl7iPUbsR6caNTG8oqcXARjnV0mbXPmsNWcrru3egBu7v8GNXV/j+u71uL5nPdpyNsHDyXI+F3veWY69by8D6ktEmdcd+BZrX3gE80eaZPzEgXgQF+Kjyg/dsIeG40hJpURD5fkIXGMn2zzoeqt6rYRb3e4Vx+tbkVPXJWvAmME5WqcKs6goZIMJHQuqbge+2XoQEYFmPDp1OqbGxHg3UlI7T1lloV1SWDAyQgLw4OhIvDF3Ej5dci9WZI5GzebPRUlKRqvyKLpJnJI96Creha7je1U60jA16VTprJeXCJTfkh9W2TEVHVXRT5QpZYsKZXpythu5XoYlGEfi0SuKSIyKHHQfP4DO4n2iC7qP74P7NOU+Lamj4oR9/pt5+P2MJHz6+AK8PCdTxmmUwHP8xIF4EBfiQ5yIl0RAaUXW6514mZghpr0K3YQDuoEV1Zc6cPRip1TEHalnZZz6kpQkyna+qrzu1FXgeE0zxkSOwoK0LMxLTlb7+jBVJ6xnlO6FI5GrHsOCkBw8DBnBfpgW7oc97/0WuFAo4LtEPiuxoLxZI6+r5L93plP2C9BMyOsEvOQWdLTSCMgJYZjcz5MkSlvxLrQW7/ASyEjECzE0QdxV9BmYgixQxzMFwNlClcA/Xyjm7/KssUj1V2sU2GQFUKRdxs3xEwfiQVyID3GS0nSugtHinHgS1yJWF/YSP6IDuEqyqdWF/AvcfpjsoZRwTxKhp6yO1dEXWoGF9y1GsjMaS6bPUPlQan/JjZoRH6EWU0g5OV1zrnw0hyDLFIA3509SqcIzKu3nkllJWU2Zb1g6Kr5D60nlc1WVhOiPmmwUfvUudr79HFoOfQ/36YPK7GTcnq06F60lu1G89o/4/In5qN62Siol3OVKcap76fiR/KYWTcIRDJPQiy6Eh4RoPCWlkhyHLA7Rq2I4ThmvwyrjJw7Eg7jIJq/ecLNh8SguMHAlziz3lw3OZaG2Gytkm4LGNuTVdXsLskRW6TK6Hs/NI2ugvtqwFRa/EDwyazYmjR2FcVwiqs0v7+oVzhYWaOkyxUxLCOZHmZH/5R8lAe9mfpgDFstGE8Brch5SRbSlzGixKuKgynBVZqP+wPfY/OoyrHt6Ib777RLseP1p7H//Rez/4wvY8voybPjtEvzw2lM4s2OtEjlM5FcclPsoApAblE8h3KYjp9Ik/EAOKoL7TKH0X5WoGwl3tRaZ4+W4OX7iQDyIi4GRwkvNcK/M56yv6xacibfa2Im7pbjdK2QHdG7UUduKPL0bolGSaOyQ4s1pcn3AheuIG5uC9OgxeGjKJPH8WP0cp6uHpUZGFy+pBRQWpLHT5hAsn5CAy0W7pfJB5LKO8Su5bogTEkA1qRWSo6pwkHwyw9rH96F27zco3/gZTn37CUq//wxnd63H9ZI9KvJ6gVUVqrpBdI5R2qJFmvF7Spco/SKxI/anqVTVuNK6kdJ0NbE4Phmn3STj5viJA/HovVfEj3DTk5i4El/iTLyJe7GxVYHL40Grx4PTja2ys20PJY090bRPwDXC9d1S7/L+R+vg19cHi6bNwLTYMVKgZWw7qbaQMRbQsVyRy5JMSLWEYZIlEO89PAvdlL8XilVgrTcgUpSla3oMBaur3IRbxLJRAT3KejF3604qB47n54tFxFGeU6woea8UOgOBqlDLUOaaEyju5P7ZMjHYX/bbiGwKEaTmxyzj5Hg5bo6fOBAP4qIcrp6Ja5T4sBFX4kucibfeJGVFHzfUhk2kysUbXci/aHCBYbMqa0iFK/Tm3PXdOFXfjvS0qXAGhWPxzBlSIRbHfZpZQazXe6n92FS9KHOnDNemmkMwyRyAjx9/AF20WM4XwGXU/lBEGDVAOqerGp0nJSpEXmszU1k3So4r+Z0Hd7VqJEDPZ4oIbiGy4ipvYl9znOiduuOo2PqV9FcWDPYaB8fF8XGcHC/HzfETB+IhO8Ybe0pr3AyHi3gSV+Ir29vL9kB8kJ17hYggblHJHS1b3cCphnbkal0gNzLkmOYCbltwuK4bJxgbyjmF4GFhSI0ZgwcmZEp0NMkeLnvtsHybnrIsquNuuPxMjiYkhQdhojkQbz84A805W8TcUzPeIISakcrO73GolGlpmJIGQQwvWXGIoVTdDPQZBBMfQIWX3VINZ6QtlX5gGTzFVt7q97z9lFU8svBPbXnGcXF8HCfHy3Fz/MSBeBAXw8v16k9tBRFP4kp85RlTxJu4u93qSXrGjllkjPrWLrUtvXYaVGLG2DlF7Z8s+x3UdsmTKv7yzQ4EDPTDpHHjsSA1WQBmdUQWtxuwmmSlu9TWM3TNxRpc1kPlZgpGerg/nswcj9wv31Vi5WwuXCLvNZh6tisQe8zHHiLQ5qcMV7Oaf0cxw+9JmNprcqpCK0ZQWUVHH0MCbTRn64/jxrG9WPfCbzA/hn3mYkCz9Jv95zg4Ho6L4+M4OV6Om+MnDrKpibGtsd7SU3IAGkPiSVzVNn0G0loE/WjrYgDtAEqb6Zh1ijbv2bZG75VvPLRACnjVZh1frvke4UODkB49UjbqE8+YnbaZEek7FOO5WR+rx7hvjyy4VovemEtIMwVjttOMDxbPU3GkC8UqgV9DU1WLFIoWmonSdMEUZ7A4XzQrlZUjpY+aCCLne3GE4QEL8OfzJdHSUX4YBz5/A7+dnoIZkVzjrPrJ/rLf7D/HwfFwXBwfx8nxctwcP3EwMPFiZGzzQ5zqOgVP4tqzN6W8/pYAfPFLlzpdKK5vxdGGrp79kvWPyE3l4WnKQ+ZDdfjwgy07DiImYiSigsMwMyEOk2OGS5hiRMAwSS1GBQWq8j3a0lxjpVciSim7ORxZpmAsHBOFL5YvRvWuDcDZYqCpDKg/BZwvgYe53RoqVnqwOgQhhVqGAje4QIkvt+YiUcB02mgZsRSy9hiuHt+LQ1++hRfnZmBWVCiybCFItIZK/9hP9pf9Zv85Do6H4+L4OE6Ol+OW1S8sQdeJLCGCJoSEnxu6BEfieRP4fP19AlBRnL3eidzaVhXLJhfoXKZKKqsNJyRE0aJ2zuLCveLyi3jowUcR5hcEh18A4iwWxFmsmJMxAeOd0Rh2V1/EhFIk6e2K9RbFsoUlS9mt4ZhoDsIDY5145+E52P3xGzh76AfJaLGuk7OWHqp4zpUG4D1NiMFoKD8/l6+KwS6WSI6iJX87Cr/+EKtfeATLJydgdmQYMqyBSLaGyM4rnBjsH/vJ/rLf7D/HwfFwXBwfx8nxctxq+RET7nprStmMCYIXcSN+xFE9V+ZvXjcRQAko76bSbR6gvKXdu4+QZPIvsb7dWG6vG11vtiYPTl9VTzrauCMbCxYsQaQlEkEDfDGs7xAsXbwUjyx6HKZAEwLvHgTbUD+MDqfVxO2/IpA+3Cn79ch+cbYwTDCHYIY9DIvjovH7OVn46vnFOPrZmzi3fRWuZX8nZe4oM2L2BP6Q1Ih6SvejvWg7Gvd9jVMb/owtry7D2/dPx2OJIzE7MhRZlgCkmYKQzGVNrOyWNWw26Rf7x36yv+w3+89xcDwcF8cnC9XJ/VoCKAxUrQ/xMSofiBvxI46CqLE1dA8lfkwA72d623olitzyHMW8xm4ldi4Z0dFeBJCdP1S+QOxdPp7kKqQyOOfEOXy+5gc88vgLePH1D9DcxkeWlOPNN/+M2VPnYKQtUiqtzUP8EOHnjxFBQYgJD5W9pseFhWJ8aBDigoYhIWCoLCOaETYELyZHYsMjU/Hd0lnY8ux87Hl5EQ68+ggOvLoEu158CD8sm4v1S6Zg5ZxkLIoMQppfP8QO7Y/RvoMQ4z8UIwP8EM0dD4MCEBUYCEegP8x+ftIv9o/9ZH/Zb/af4+B4OC4Zn1ExriWAWgGpC60uafHc2C24ET+Ft94W+sec8LciqDeb8OvcZLq2tROFdTfUw9B04l51wIh56J3EWT8kO+u65Cl6OfXdskpcngPWDllbVtLQjtLLHnkm2PmrLhSePovvNu3GO+/+GU8+vhwL5i7A1AlTkJaYivjR4xDjiIQzJAwWPz9YBw1ErE9ffDQnGVe/ex9N695B9Ue/xYl3n0TJm7/B8XeWouyD5Tj32cu4+s0HqF75KmYED4L5jlsQ7jMY1sBAOM1WREdEISZ6NMaPj0daxkRMnz0PD/9mmfSL/WM/2V/2m/3nOGQ8HBcVq8ZA7fmjuEAV2urGLezrbghu6lGHPajeJIb+lgA3v2QzVwA1V9pRUN+unsko9e69a1y0Yhbtrx7sYJitss+cPDeGT7Lj81i61S7ifKhBUxdKuck3H1/VATS084FwHpy71IHqhmuovNCEipoLqKiolgLe0oIcfLR0IdYumgTPztXA3vXAvvXA/rXA/r8A+9fBs3cd3HvWonv3WrRs/BzvL5yOLV9+jOryUpw9dwHlNRdwrPICCmrqUVR7GaebO6R4lrU77Bf7J/2k/JaH0alxiFkpY9K2vi7fMSocepafugUn4qUeZfUTkr/n9c8JwBdvQTlW0dImD7I0Hl3C+EbvvdGMxR3iwMl1bQMbKTjGQvRe+sZzZ4pl4TcJ0o2Sxg5pJ5u7UH3NhYZWD5ovX0dNeRmO7tyEVa8sx5tzU1H25Wto3/kVrm9djevb2VahlW3HGlzbvhpXmdrctx6dxbuw7Z1n8eqDs/DDpx+g5MhBVFVUoe5yK87e4Gof7n/RgYLGLuQ38cl6qm/sp+FEiR2vl5qKQyXRAaNYQVk9RtyMuBAf4qTk/j99/esEoCS77vLgFGNFsruW+uHeNrB3fYHRKf3IP3nynF4VboBvXJdNi5gtauhESVM7Ki93oarxOrJzCrDmk4/x2lOP4YUHZmFp5jh8+vhc1Gz+RGx+WWdWuAUduT+gLft7tB3+TrWjP0hyR4J2Z/PRWXYI2z98Ea/Om4AnJ8TjD4vm461nnsL6VWtQcKICFc0dsuksFabx1AtZsms8xNO7aLFnbGoxS48vZBCAuBAf4qQefPRPX/8aAdRL3fByt1uem0iFZLCn4Zz15JLVkhyZFTcRQJrxHbYGFwr5eNiWDtTUtmDHpk1485kn8PLDc/DlC4+iYP0HqDu4AZ8vnYuT698FGgvhqdgHT9VBbfmwCoJJeB3K9hZn5UrCB+fygMYT2Pb6cnyyeBYu5/yAgnXv48sVj8qSqE/efB15BcdR09LZa1nuTQToNR7hAj1ew+EiDsSDuBAfr9L956//CAEUCcQy6nLjeP11ZZ5qxaQIoAEWmWgAboRk1Xv1HUMkdYvSO3e5DUcPH8LrTz2C1349Gwc+fQVXcr8BKvcAVfuBM4dQuflj/OnhiTi3/TPgYi5QQ9APwV19GO6abLhZ7lLNKgrW8rBskeAXyFYE+avewlvz0nFu+5dS1YDKvUD5bjTuX48f3nwOryxagDUfvI/S8rM9Y7ip7951XXoMwgHa4CAOxIO4KCvnXwKfr3+dAN7ohX740uUuF443tMou69xLSGa/Ue11Uyzcu/2BEagSedqNE02dONNwCWtX/hm/WzgTez95GZ0ntwE1e4HSrXCVboO7bBdc5XuAs4dRsu5tvPdAOg5/+hK6af/X0tHKk8Q5zjKuw6YqFlgycrVoOza9+jjemZ+G6s0rgTOH4Tq9EyjdCc9pLv7eBVTuR/2Br7Hm+UfxhyUPevsooPcigjEmqRzUiRbZ5Kq2Q3AgHt5Hw/zrRPjHBBDHQZ3ddO4W8+pKlwul1Al1mghaWRlEMGaPKC3Zd1QH9uo7cKqlE+U1F/Hei8/ij08sQP2RDcC5A0D5VnhObYabBCjbBXf5XiVyKvcDZ7Nxbs9XWPPsffji6Tk48MmLqN75JS7nbURryTbcKNqOpiN/xam/rsQPbzyJDxdNxvrnHkBL9jdCQLlfxW54SnfBXboT7tLt8Jxm7c8uoGwvCte97815GEVqBicY4KscCQ0LPmu+Q8ZPHNQzYdSzlXuw633+k6+fJoDxJI1eV7zXelrPE7Qrmtvk6Xp8RkrPnnJqAF6ZqcPYOQ2dON3SieOnSvH6049i3R+WwsWZWLMHrtLNcJVugrt0M9xl2+Au3w03K9Eq9stRzs+qqrczO7/Eng+ewYbfPYS/PHsfvlq2AGuenoc1yxfg29/9Goc/eRH1B9cDNdQV+9W95H674S5j2wV3GT3pnfCUssqNq/X3o+nw92qXYM0JvcdhcDPHyfFy3By/wG5EEHq13nrgbzGV179KgL9zXf9Ghxs4e7UDRXVUztzOwMgd6BlvPOa2vhOlLZ04dvwUXlp8Hza/9yxwZj88FVvhLv0B7rLN8JRthbtsC9zlW+Eu3wVP5T54ygn+Hngq9+gjuYF1+8wl70f78e24mrcR1/K5TwQLgFnPcwQ4w4QLOWgPPJoAIAF4XrZTmqdsGzyl20QkuYQb9ko/Jemk+y++jE6wcHwcJ8fLcRsY/F2M/vH1HxNA5JY8zM0D46lKP9V635CNyQU+pq/+RidK6DEzjK2tAwU+Z34Xjjd1oLSiBq8+thCb314OVO0FCPhpPfPLCfw2LxE85TsVeBpAvndL2yVKlNdRyVgQZ7luVawtouji3xJsnu9Sf1vBEhWeGwTYrjitdAtALuA5OaF8l/RXHkptOJOU93VqfBwnx+t9yOnfweVHzfuUqh8ZqD0EUDfoeYyVx/Xjm7rdmjA/8WP8TBEQuNrpQqk8AqUVR7WVlNfgwrHGTpypv4Q/vrAMf3lhsQKunAPeAncZ5f1mmfUeEqCcYGzXBNipgTeA3CHfF7DKeK4+85Tthqdsj4gWBbAC2y3f5z2Nxus7Ad63gr/B+2wF5H7kRE6IrdJf9luFVTplPBwXx2fA1xuT3nj0xst73cBT46w/u5kAP2YV4/hT572/5+2IEMIjJRfnr3ag8OI15F5sRVF9G862tGPj6i/x1q9no+34NqB6Lzx6BirACSrFDpu6ppoCTcAmIQRY4zOe6ybihAqWhDAIwL/RwJdtF4IbhEDFDkAToIcw2+HmfUu3w3V6i/Sb/ec4OB7jAc0cpwHyT+FhXLv5/CewlUdI/s1jrFT72xvffN77mmrsmHqsPf+/3NmNiqZrOF13BQW5Bfj9w3NRs2OVyGdjRksTQhhgbIeL5wRMrm+Bq5RcwhmqgFezWhFD/laA5jnv1aNgeR9+ztlNWS/HXkQg6EKECgU87yHcVqq4hqKR/ec41Kg4Xj5j86elwU9h1NNufs/vqO/1IoCb31Jf6KUDbr6Z8ZL3N1m8/DvFZoobXB7gelsHVn34Lv763gtixXiq9sFTQeWoGk1CAt57Rv9ILFApS1OAqmt6xsp1zSVe+U7fQXONENPgKGP2U9n2NE/ldrgrea7EnWrkKvoKOzRQGht5+Joeq7SfwOSncPvRkwrVQ1P56urqwv8PfSDQHO7zZhkAAAAASUVORK5CYII=";

@interface GeoSimJoystickHUD : UIView
@property (nonatomic, copy) void (^onClose)(void);
- (void)refreshSpeedTitle;
@end

@interface GeoSimJoystickHUD ()
@property (nonatomic, strong) UIView *padView;
@property (nonatomic, strong) UIView *knobView;
@property (nonatomic, strong) UIButton *speedButton;
@property (nonatomic, assign) BOOL draggingKnob;
@end

@implementation GeoSimJoystickHUD

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(24, 220, 140, 176)];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
        self.layer.cornerRadius = 18.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18].CGColor;
        self.clipsToBounds = YES;

        // Top bar (drag handle + speed + close)
        UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 34)];
        topBar.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
        [self addSubview:topBar];

        UIPanGestureRecognizer *dragHUD = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragHUD:)];
        [topBar addGestureRecognizer:dragHUD];

        _speedButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _speedButton.frame = CGRectMake(8, 3, 92, 28);
        _speedButton.titleLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightSemibold];
        [_speedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _speedButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_speedButton addTarget:self action:@selector(cycleSpeed) forControlEvents:UIControlEventTouchUpInside];
        [topBar addSubview:_speedButton];
        [self refreshSpeedTitle];

        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(108, 3, 28, 28);
        [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        [closeBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
        [topBar addSubview:closeBtn];

        // Pad
        CGFloat padSize = 112.0;
        _padView = [[UIView alloc] initWithFrame:CGRectMake((140.0 - padSize) / 2.0, 44.0, padSize, padSize)];
        _padView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
        _padView.layer.cornerRadius = padSize / 2.0;
        _padView.layer.borderWidth = 1.5;
        _padView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor;
        [self addSubview:_padView];

        // Crosshair lines inside pad
        UIView *hLine = [[UIView alloc] initWithFrame:CGRectMake(12, padSize / 2.0 - 0.5, padSize - 24, 1)];
        hLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
        hLine.userInteractionEnabled = NO;
        [_padView addSubview:hLine];

        UIView *vLine = [[UIView alloc] initWithFrame:CGRectMake(padSize / 2.0 - 0.5, 12, 1, padSize - 24)];
        vLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
        vLine.userInteractionEnabled = NO;
        [_padView addSubview:vLine];

        // Knob
        CGFloat knobSize = 44.0;
        _knobView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, knobSize, knobSize)];
        _knobView.center = CGPointMake(padSize / 2.0, padSize / 2.0);
        _knobView.backgroundColor = [UIColor systemBlueColor];
        _knobView.layer.cornerRadius = knobSize / 2.0;
        _knobView.layer.shadowColor = [UIColor blackColor].CGColor;
        _knobView.layer.shadowOpacity = 0.35;
        _knobView.layer.shadowRadius = 4.0;
        _knobView.userInteractionEnabled = NO;
        [_padView addSubview:_knobView];
    }
    return self;
}

- (void)refreshSpeedTitle {
    double spd = [GeoSimEngine shared].speedMetersPerSecond;
    NSString *tag = (spd <= 2.2) ? @"步" : (spd <= 7.0 ? @"骑" : @"车");
    [self.speedButton setTitle:[NSString stringWithFormat:@"%@ %.1fm/s", tag, spd] forState:UIControlStateNormal];
}

- (void)cycleSpeed {
    GeoSimEngine *eng = [GeoSimEngine shared];
    double s = eng.speedMetersPerSecond;
    if (s < 2.5) eng.speedMetersPerSecond = 5.0;
    else if (s < 8.0) eng.speedMetersPerSecond = 15.0;
    else eng.speedMetersPerSecond = 1.5;
    [self refreshSpeedTitle];
}

- (void)closeTapped {
    [[GeoSimEngine shared] setJoystickVector:CGPointZero];
    if (self.onClose) self.onClose();
}

- (void)handleDragHUD:(UIPanGestureRecognizer *)gr {
    UIView *superview = self.superview;
    if (!superview) return;
    CGPoint delta = [gr translationInView:superview];
    CGPoint c = self.center;
    c.x = fmax(self.bounds.size.width / 2.0, fmin(superview.bounds.size.width - self.bounds.size.width / 2.0, c.x + delta.x));
    c.y = fmax(self.bounds.size.height / 2.0 + 30.0, fmin(superview.bounds.size.height - self.bounds.size.height / 2.0, c.y + delta.y));
    self.center = c;
    [gr setTranslation:CGPointZero inView:superview];
}

- (void)updateKnobForTouch:(UITouch *)touch {
    CGPoint pt = [touch locationInView:self.padView];
    CGFloat radius = self.padView.bounds.size.width / 2.0;
    CGFloat maxOffset = radius - 22.0;
    CGFloat dx = pt.x - radius;
    CGFloat dy = pt.y - radius;
    CGFloat dist = hypot(dx, dy);
    if (dist > maxOffset && dist > 0.001) {
        dx = dx * (maxOffset / dist);
        dy = dy * (maxOffset / dist);
    }
    self.knobView.center = CGPointMake(radius + dx, radius + dy);
    // UIKit y grows downward, whereas North (+y) is upward
    CGPoint vec = CGPointMake(dx / maxOffset, -dy / maxOffset);
    [[GeoSimEngine shared] setJoystickVector:vec];
}

- (void)resetKnob {
    CGFloat radius = self.padView.bounds.size.width / 2.0;
    [UIView animateWithDuration:0.15 animations:^{
        self.knobView.center = CGPointMake(radius, radius);
    }];
    [[GeoSimEngine shared] setJoystickVector:CGPointZero];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    if (!t) return;
    CGPoint pt = [t locationInView:self.padView];
    if (CGRectContainsPoint(CGRectInset(self.padView.bounds, -10, -10), pt)) {
        self.draggingKnob = YES;
        [self updateKnobForTouch:t];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.draggingKnob) return;
    UITouch *t = touches.anyObject;
    if (t) [self updateKnobForTouch:t];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.draggingKnob) {
        self.draggingKnob = NO;
        [self resetKnob];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.draggingKnob) {
        self.draggingKnob = NO;
        [self resetKnob];
    }
}

@end

#pragma mark - GeoSimOverlay

@interface GeoSimOverlay ()
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) GeoSimJoystickHUD *joystickHUD;
@property (nonatomic, weak) UIWindow *attachedWindow;
@property (nonatomic, assign) BOOL buttonHidden;
@end

@implementation GeoSimOverlay

+ (instancetype)shared {
    static GeoSimOverlay *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[GeoSimOverlay alloc] init];
    });
    return inst;
}

+ (void)install {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[GeoSimOverlay shared] ensureAttached];
        });
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:GeoSimEngineStateDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [[GeoSimOverlay shared] refreshButtonAppearance];
    }];
}

+ (void)setFloatingButtonHidden:(BOOL)hidden {
    GeoSimOverlay *ov = [GeoSimOverlay shared];
    ov.buttonHidden = hidden;
    ov.floatingButton.hidden = hidden;
}

+ (void)setJoystickHUDVisible:(BOOL)visible {
    GeoSimOverlay *ov = [GeoSimOverlay shared];
    [ov ensureAttached];
    ov.joystickHUD.hidden = !visible;
    if (visible) {
        [ov.joystickHUD refreshSpeedTitle];
        [ov.attachedWindow bringSubviewToFront:ov.joystickHUD];
    } else {
        [[GeoSimEngine shared] setJoystickVector:CGPointZero];
    }
}

+ (BOOL)isJoystickHUDVisible {
    GeoSimOverlay *ov = [GeoSimOverlay shared];
    return ov.joystickHUD && !ov.joystickHUD.hidden;
}

- (nullable UIWindow *)findKeyWindow {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        if (ws.activationState == UISceneActivationStateForegroundActive ||
            ws.activationState == UISceneActivationStateForegroundInactive) {
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow && !w.hidden) return w;
            }
            if (ws.windows.firstObject) return ws.windows.firstObject;
        }
    }
    return nil;
}

- (void)ensureAttached {
    UIWindow *win = [self findKeyWindow];
    if (!win) return;

    if (!self.floatingButton) {
        CGFloat size = 48.0;
        CGFloat x = win.bounds.size.width - size - 14.0;
        CGFloat y = 110.0;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(x, y, size, size);
        btn.backgroundColor = [UIColor clearColor];
        btn.layer.cornerRadius = size / 2.0;
        btn.clipsToBounds = YES;
        btn.imageView.contentMode = UIViewContentModeScaleAspectFill;
        NSData *iconData = [[NSData alloc] initWithBase64EncodedString:kDoubaoIconBase64 options:0];
        UIImage *iconImg = iconData ? [UIImage imageWithData:iconData] : nil;
        if (iconImg) {
            [btn setImage:iconImg forState:UIControlStateNormal];
        }
        [btn addTarget:self action:@selector(openControlPanel) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonPan:)];
        [btn addGestureRecognizer:pan];

        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonLongPress:)];
        lp.minimumPressDuration = 0.45;
        [btn addGestureRecognizer:lp];

        self.floatingButton = btn;
        [self refreshButtonAppearance];
    }

    if (!self.joystickHUD) {
        self.joystickHUD = [[GeoSimJoystickHUD alloc] initWithFrame:CGRectZero];
        self.joystickHUD.hidden = YES;
        __weak typeof(self) weakSelf = self;
        self.joystickHUD.onClose = ^{
            weakSelf.joystickHUD.hidden = YES;
        };
    }

    if (self.attachedWindow != win) {
        self.attachedWindow = win;
        [win addSubview:self.floatingButton];
        [win addSubview:self.joystickHUD];

        // 3-finger double-tap toggles floating button visibility
        UITapGestureRecognizer *threeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleThreeFingerDoubleTap)];
        threeTap.numberOfTouchesRequired = 3;
        threeTap.numberOfTapsRequired = 2;
        threeTap.cancelsTouchesInView = NO;
        [win addGestureRecognizer:threeTap];
    }

    self.floatingButton.hidden = self.buttonHidden;
    [win bringSubviewToFront:self.floatingButton];
    if (!self.joystickHUD.hidden) {
        [win bringSubviewToFront:self.joystickHUD];
    }
}

- (void)refreshButtonAppearance {
    // Pure circular Doubao logo without any text or outer border
    self.floatingButton.backgroundColor = [UIColor clearColor];
}

- (void)handleThreeFingerDoubleTap {
    self.buttonHidden = !self.buttonHidden;
    self.floatingButton.hidden = self.buttonHidden;
    if (!self.buttonHidden) {
        [self.attachedWindow bringSubviewToFront:self.floatingButton];
    }
}

- (void)handleButtonPan:(UIPanGestureRecognizer *)gr {
    UIView *win = self.attachedWindow;
    if (!win) return;
    CGPoint delta = [gr translationInView:win];
    CGPoint c = self.floatingButton.center;
    c.x = fmax(self.floatingButton.bounds.size.width / 2.0, fmin(win.bounds.size.width - self.floatingButton.bounds.size.width / 2.0, c.x + delta.x));
    c.y = fmax(50.0, fmin(win.bounds.size.height - 40.0, c.y + delta.y));
    self.floatingButton.center = c;
    [gr setTranslation:CGPointZero inView:win];
}

- (nullable UIViewController *)topViewController {
    UIWindow *win = [self findKeyWindow];
    UIViewController *topVC = win.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

- (void)verifyPasswordAndRun:(void (^)(UIViewController *topVC))onAuthorized {
    UIViewController *topVC = [self topViewController];
    if (!topVC || [topVC isKindOfClass:[GeoSimViewController class]]) return;

    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"请输入访问密码"
                                                                message:@"验证通过后方可使用全部功能"
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull tf) {
        tf.placeholder = @"请输入密码";
        tf.secureTextEntry = YES;
        tf.keyboardType = UIKeyboardTypeNumberPad;
    }];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [ac addAction:[UIAlertAction actionWithTitle:@"解锁" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *pwd = ac.textFields.firstObject.text ?: @"";
        if ([GeoSimEngine verifyAccessPassword:pwd]) {
            UIViewController *currentTop = [weakSelf topViewController];
            if (currentTop && onAuthorized) {
                onAuthorized(currentTop);
            }
        } else {
            UIViewController *currentTop = [weakSelf topViewController];
            if (currentTop) {
                UIAlertController *err = [UIAlertController alertControllerWithTitle:@"密码错误"
                                                                             message:@"输入密码错误，禁止进入软件！"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
                [err addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
                [currentTop presentViewController:err animated:YES completion:nil];
            }
        }
    }]];
    [topVC presentViewController:ac animated:YES completion:nil];
}

- (void)handleButtonLongPress:(UILongPressGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        if (!self.joystickHUD.hidden) {
            [GeoSimOverlay setJoystickHUDVisible:NO];
            return;
        }
        [self verifyPasswordAndRun:^(UIViewController *topVC) {
            [GeoSimOverlay setJoystickHUDVisible:YES];
        }];
    }
}

- (void)openControlPanel {
    [self verifyPasswordAndRun:^(UIViewController *topVC) {
        GeoSimViewController *panel = [[GeoSimViewController alloc] init];
        panel.modalPresentationStyle = UIModalPresentationPageSheet;
        [topVC presentViewController:panel animated:YES completion:nil];
    }];
}

@end
